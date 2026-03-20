# Translate Meditate content

You are an automated translation tool.

## Inputs (read these files)

- `ConnectIQStore/MeditateStoreDescription-en.txt`
- `UserGuide.md`
- `Advertisement.md`

## Outputs (write exactly these files)

- German (`de`):
  - `generated/ConnectIQStore/MeditateStoreDescription-de.txt`
  - `generated/UserGuides/UserGuide-de.md`
  - `generated/Advertisements/Advertisement-de.md`
- Portuguese (`pt`):
  - `generated/ConnectIQStore/MeditateStoreDescription-pt.txt`
  - `generated/UserGuides/UserGuide-pt.md`
  - `generated/Advertisements/Advertisement-pt.md`
- Korean (`ko`):
  - `generated/ConnectIQStore/MeditateStoreDescription-ko.txt`
  - `generated/UserGuides/UserGuide-ko.md`
  - `generated/Advertisements/Advertisement-ko.md`
- Spanish (`es`):
  - `generated/ConnectIQStore/MeditateStoreDescription-es.txt`
  - `generated/UserGuides/UserGuide-es.md`
  - `generated/Advertisements/Advertisement-es.md`
- Chinese Simplified (`zh`):
  - `generated/ConnectIQStore/MeditateStoreDescription-zh.txt`
  - `generated/UserGuides/UserGuide-zh.md`
  - `generated/Advertisements/Advertisement-zh.md`
- Ukrainian (`uk`):
  - `generated/ConnectIQStore/MeditateStoreDescription-uk.txt`
  - `generated/UserGuides/UserGuide-uk.md`
  - `generated/Advertisements/Advertisement-uk.md`
- Japanese (`ja`):
  - `generated/ConnectIQStore/MeditateStoreDescription-ja.txt`
  - `generated/UserGuides/UserGuide-ja.md`
  - `generated/Advertisements/Advertisement-ja.md`
- French (`fr`):
  - `generated/ConnectIQStore/MeditateStoreDescription-fr.txt`
  - `generated/UserGuides/UserGuide-fr.md`
  - `generated/Advertisements/Advertisement-fr.md`

Do not modify any other files.

## Store description translation rules (`generated/ConnectIQStore/MeditateStoreDescription-*.txt`)

- You are given an English description of a Garmin watch app.
- Translate it into the target language (ISO 639-1 2-letter code shown above).
- Output must be suitable for a `.txt` file:
  - No Markdown.
  - Preserve the same formatting style as the input (paragraph breaks, line breaks).
- No boilerplate.
- You may rewrite for clarity and reading flow.
- Keep sentences easy to understand (avoid complicated sentences).
- Make it sound casual and native in the target language.

## User guide translation rules (`generated/UserGuides/UserGuide-*.md`)

- You are given an English user guide (Markdown) for a Garmin watch app about meditation and breathwork.
- Translate it into the target language (ISO 639-1 2-letter code shown above).
- Output must be suitable for a Markdown file:
  - Preserve Markdown structure, headings, lists, code blocks, and links.
  - Preserve the same formatting style as the input.
- No boilerplate.
- You may rewrite for clarity and reading flow.
- Keep sentences easy to understand (avoid complicated sentences).
- Make it sound casual and native in the target language.

## Advertisement translation rules (`generated/Advertisements/Advertisement-*.md`)

- You are given an English advertisement page (Markdown) for a Garmin watch app about meditation and breathwork.
- Translate it into the target language (ISO 639-1 2-letter code shown above).
- Output must be suitable for a Markdown file:
  - Preserve Markdown structure, headings, lists, code blocks, and links.
  - Preserve the YAML front matter keys (layout, title, subtitle, permalink, share-title, share-description) — translate only the values.
  - Preserve the same formatting style as the input.
- No boilerplate.
- You may rewrite for clarity and reading flow.
- Keep sentences easy to understand (avoid complicated sentences).
- Make it sound casual and native in the target language.

## General

- Produce human-readable text.
- Do not add extra commentary or wrap the output in code fences.
