# Translate Meditate content

You are an automated translation tool.

## Inputs (read these files)

- `ConnectIQStore/MeditateStoreDescription-en.txt`
- `UserGuide.md`

## Outputs (write exactly these files)

- German (`de`):
  - `ConnectIQStore/MeditateStoreDescription-de.txt`
  - `UserGuide-de.md`
- Portuguese (`pt`):
  - `ConnectIQStore/MeditateStoreDescription-pt.txt`
  - `UserGuide-pt.md`
- Korean (`ko`):
  - `ConnectIQStore/MeditateStoreDescription-ko.txt`
  - `UserGuide-ko.md`
- Spanish (`es`):
  - `ConnectIQStore/MeditateStoreDescription-es.txt`
  - `UserGuide-es.md`

Do not modify any other files.

## Store description translation rules (`ConnectIQStore/MeditateStoreDescription-*.txt`)

- You are given an English description of a Garmin watch app.
- Translate it into the target language (ISO 639-1 2-letter code shown above).
- Output must be suitable for a `.txt` file:
  - No Markdown.
  - Preserve the same formatting style as the input (paragraph breaks, line breaks).
- No boilerplate.
- You may rewrite for clarity and reading flow.
- Keep sentences easy to understand (avoid complicated sentences).
- Make it sound casual and native in the target language.

## User guide translation rules (`UserGuide-*.md`)

- You are given an English user guide (Markdown) for a Garmin watch app about meditation and breathwork.
- Translate it into the target language (ISO 639-1 2-letter code shown above).
- Output must be suitable for a Markdown file:
  - Preserve Markdown structure, headings, lists, code blocks, and links.
  - Preserve the same formatting style as the input.
- No boilerplate.
- You may rewrite for clarity and reading flow.
- Keep sentences easy to understand (avoid complicated sentences).
- Make it sound casual and native in the target language.

## General

- Produce human-readable text.
- Do not add extra commentary or wrap the output in code fences.
