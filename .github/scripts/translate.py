#!/usr/bin/env python3
"""Translate the store description, user guide, ad page and hero banner into generated/.

A target is redone, always as a whole file, only when its source or prompt changed since
it was last translated; generated/translation-state-*.json records what each target was
made from. The text and images commands need OPENAI_API_KEY.

  translate.py plan --scope S      print text=/images= lines for $GITHUB_OUTPUT
  translate.py text --scope S      translate the text files
  translate.py images --scope S    translate the hero banner
  translate.py mark-current        record every existing target as up to date, no API calls
"""
import argparse
import base64
import hashlib
import json
import os
import re
import struct
import sys
import threading
from collections import OrderedDict, namedtuple
from concurrent.futures import ThreadPoolExecutor, as_completed

TEXT_MODEL = "gpt-6-sol"
TEXT_EFFORT = "low"
IMAGE_MODEL = "gpt-image-2.5-sunburst"
IMAGE_QUALITY = "high"

LANGUAGES = OrderedDict(
    [
        ("de", "German"),
        ("pt", "Brazilian Portuguese"),
        ("ko", "Korean"),
        ("es", "Spanish"),
        ("zh", "Chinese Simplified"),
        ("uk", "Ukrainian"),
        ("ja", "Japanese"),
        ("fr", "French"),
    ]
)

TEXT_PROMPT = ".github/prompts/translate-content.md"
TEXT_STATE = "generated/translation-state-text.json"
TEXT_SOURCES = [  # source, kind as named in the prompt, target
    (
        "ConnectIQStore/MeditateStoreDescription-en.txt",
        "store description",
        "generated/ConnectIQStore/MeditateStoreDescription-{lang}.txt",
    ),
    ("UserGuide.md", "user guide", "generated/UserGuides/UserGuide-{lang}.md"),
    ("Advertisement.md", "advertisement", "generated/Advertisements/Advertisement-{lang}.md"),
]

IMAGE_PROMPT = ".github/prompts/translate-hero.txt"
IMAGE_STATE = "generated/translation-state-images.json"
IMAGE_SOURCE = "userGuideScreenshots/hero_meditate.png"
IMAGE_TARGET = "generated/HeroImages/hero_meditate-{lang}.png"

# workflow_dispatch dropdown label -> (text mode, image mode)
SCOPES = OrderedDict(
    [
        ("changed only", ("changed", "changed")),
        ("everything", ("all", "all")),
        ("text only", ("all", "skip")),
        ("hero images only", ("skip", "all")),
    ]
)

Target = namedtuple("Target", "path source kind lang stamp")
output_lock = threading.Lock()


def emit(stream, line):
    with output_lock:
        stream.write(line + "\n")
        stream.flush()


def log(message):
    emit(sys.stderr, message)


def fail(path, error):
    emit(sys.stdout, "::error::%s: %s" % (path, str(error).replace("\n", " ")))


def read_text(path):
    with open(path, encoding="utf-8") as f:
        return f.read().replace("\r\n", "\n")


def write_text(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def digest(path, text):
    with open(path, "rb") as f:
        data = f.read()
    if text:
        data = data.replace(b"\r\n", b"\n")
    return hashlib.sha256(data).hexdigest()[:16]


def text_targets():
    prompt = digest(TEXT_PROMPT, True)
    targets = []
    for source, kind, pattern in TEXT_SOURCES:
        stamp = {"prompt": prompt, "source": digest(source, True)}
        for lang in LANGUAGES:
            targets.append(Target(pattern.format(lang=lang), source, kind, lang, stamp))
    return targets


def image_targets():
    stamp = {"prompt": digest(IMAGE_PROMPT, True), "source": digest(IMAGE_SOURCE, False)}
    return [
        Target(IMAGE_TARGET.format(lang=lang), IMAGE_SOURCE, "hero image", lang, stamp)
        for lang in LANGUAGES
    ]


def load_state(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def save_state(path, state):
    write_text(path, json.dumps(state, indent=2, sort_keys=True) + "\n")


def select(targets, state_path, mode):
    if mode == "skip":
        return []
    if mode == "all":
        return targets
    state = load_state(state_path)
    return [t for t in targets if state.get(t.path) != t.stamp or not os.path.exists(t.path)]


def plan(scope):
    text_mode, image_mode = SCOPES[scope]
    text = select(text_targets(), TEXT_STATE, text_mode)
    images = select(image_targets(), IMAGE_STATE, image_mode)
    for t in text + images:
        log("to translate: " + t.path)
    if not text and not images:
        log("nothing to translate")
    print("text=" + ("true" if text else "false"))
    print("images=" + ("true" if images else "false"))


def mark_current():
    for targets, state_path in ((text_targets(), TEXT_STATE), (image_targets(), IMAGE_STATE)):
        state = load_state(state_path)
        for t in targets:
            if os.path.exists(t.path):
                state[t.path] = t.stamp
        save_state(state_path, state)
        log("marked %d targets current in %s" % (len(state), state_path))


def paragraphs(text):
    return len([p for p in re.split(r"\n\s*\n", text.strip()) if p.strip()])


def check(path, source, text):
    if not text.strip():
        return ["empty reply"]
    problems = []
    if path.endswith(".md"):
        for name, pattern in (("headings", r"^#{1,6} "), ("anchors", r"<a id="), ("links", r"\]\(")):
            want = len(re.findall(pattern, source, re.M))
            got = len(re.findall(pattern, text, re.M))
            if want != got:
                problems.append("%d %s instead of %d" % (got, name, want))
        if source.startswith("---\n") and not text.startswith("---\n"):
            problems.append("front matter missing")
        for key in ("layout", "permalink"):
            line = re.search(r"^%s:.*$" % key, source, re.M)
            if line and line.group(0) not in text.split("\n"):
                problems.append(key + " line changed")
    else:
        want, got = paragraphs(source), paragraphs(text)
        if want != got:
            problems.append("%d paragraphs instead of %d" % (got, want))
    return problems


def clean(text, source):
    text = text.replace("\r\n", "\n").strip("\n")
    lines = text.split("\n")
    # drop a code fence wrapped around the whole reply
    if len(lines) > 2 and lines[0].startswith("```") and lines[-1].strip() == "```":
        if not source.startswith("```"):
            text = "\n".join(lines[1:-1]).strip("\n")
    return text + "\n"


def translate_file(client, instructions, target):
    import openai

    source = read_text(target.source)
    # source first: requests for the same file share the cached prefix, only the last line differs
    request = "<source>\n%s\n</source>\n\nTranslate the %s above into %s (%s). Reply with the complete translated file only." % (
        source,
        target.kind,
        LANGUAGES[target.lang],
        target.lang,
    )
    args = dict(
        model=TEXT_MODEL,
        instructions=instructions,
        input=request,
        reasoning={"effort": TEXT_EFFORT},
        max_output_tokens=8000 + len(source),
    )
    try:
        response = client.responses.create(service_tier="flex", **args)
    except openai.RateLimitError:  # flex has no capacity right now
        log(target.path + ": flex unavailable, using the standard tier")
        response = client.responses.create(service_tier="default", **args)
    if response.status != "completed":
        raise RuntimeError("response %s: %s" % (response.status, response.incomplete_details))
    text = clean(response.output_text, source)
    problems = check(target.path, source, text)
    if problems:
        raise RuntimeError("rejected, " + "; ".join(problems))
    return text, response


def usage_row(target, response):
    u = response.usage
    cached = getattr(u.input_tokens_details, "cached_tokens", 0) or 0
    reasoning = getattr(u.output_tokens_details, "reasoning_tokens", 0) or 0
    return [target.path, response.service_tier, u.input_tokens, cached, u.output_tokens, reasoning]


def report(rows):
    header = ["file", "tier", "input", "cached", "output", "reasoning"]
    rows = sorted(rows)
    totals = ["total", ""] + [sum(r[i] for r in rows) for i in range(2, 6)]
    lines = ["| " + " | ".join(header) + " |", "|" + " --- |" * len(header)]
    lines += ["| " + " | ".join(str(c) for c in r) + " |" for r in rows + [totals]]
    log("\n".join(lines))
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as f:
            f.write("### Text translation tokens\n\n" + "\n".join(lines) + "\n")


def translate_text(scope):
    targets = select(text_targets(), TEXT_STATE, SCOPES[scope][0])
    if not targets:
        log("no text to translate")
        return True
    from openai import OpenAI

    client = OpenAI()
    instructions = read_text(TEXT_PROMPT)
    state = load_state(TEXT_STATE)
    lock = threading.Lock()
    rows, failures = [], []

    def run(target):
        try:
            text, response = translate_file(client, instructions, target)
        except Exception as e:
            fail(target.path, e)
            with lock:
                failures.append(target.path)
            return
        write_text(target.path, text)
        with lock:
            state[target.path] = target.stamp
            rows.append(usage_row(target, response))
        log("translated " + target.path)

    groups = OrderedDict()
    for t in targets:
        groups.setdefault(t.source, []).append(t)
    with ThreadPoolExecutor(max_workers=8) as pool:
        # one language per file first, so the other seven read its prompt cache instead of writing their own
        first = {pool.submit(run, group[0]): group[1:] for group in groups.values()}
        rest = []
        for done in as_completed(first):
            done.result()
            rest += [pool.submit(run, t) for t in first[done]]
        for future in rest:
            future.result()
    save_state(TEXT_STATE, state)
    report(rows)
    return not failures


def png_size(data):
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", data[16:24])


def translate_images(scope):
    targets = select(image_targets(), IMAGE_STATE, SCOPES[scope][1])
    if not targets:
        log("no hero image to translate")
        return True
    from openai import OpenAI

    client = OpenAI()
    with open(IMAGE_SOURCE, "rb") as f:
        source = f.read()
    size = png_size(source)
    if size[0] % 16 or size[1] % 16:
        fail(IMAGE_SOURCE, "%dx%d, %s needs both sides divisible by 16" % (size + (IMAGE_MODEL,)))
        return False
    prompt = read_text(IMAGE_PROMPT)
    state = load_state(IMAGE_STATE)
    failures = []
    for target in targets:
        log("translating hero image to " + LANGUAGES[target.lang])
        try:
            result = client.images.edit(
                model=IMAGE_MODEL,
                image=(os.path.basename(IMAGE_SOURCE), source, "image/png"),
                prompt=prompt.replace("{language}", LANGUAGES[target.lang]),
                size="%dx%d" % size,
                quality=IMAGE_QUALITY,
                output_format="png",
            )
            image = base64.b64decode(result.data[0].b64_json)
            if png_size(image) != size:
                raise RuntimeError("got %dx%d instead of %dx%d" % (png_size(image) + size))
        except Exception as e:
            fail(target.path, e)
            failures.append(target.path)
            continue
        os.makedirs(os.path.dirname(target.path), exist_ok=True)
        with open(target.path, "wb") as f:
            f.write(image)
        state[target.path] = target.stamp
        log("translated " + target.path)
    save_state(IMAGE_STATE, state)
    return not failures


def main():
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["plan", "text", "images", "mark-current"])
    parser.add_argument("--scope", default="changed only", choices=list(SCOPES))
    args = parser.parse_args()
    if args.command == "plan":
        plan(args.scope)
        return 0
    if args.command == "mark-current":
        mark_current()
        return 0
    ok = translate_text(args.scope) if args.command == "text" else translate_images(args.scope)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
