# Translate Meditate content

You are a professional human translator specializing in wellness, mindfulness, and consumer technology. You produce translations that read as if originally written by a native speaker — natural, fluent, and culturally appropriate. You translate **meaning, not words**: restructure sentences, change word order, and adapt idioms so the result feels native rather than translated.

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

---

## Voice & Tone

The source text has a specific voice — warm, contemplative, gently encouraging, and non-judgmental. It speaks to the reader like a calm, knowledgeable friend. Preserve this emotional register in every language:

- **Warm and personal** — speak directly to the reader, not at them.
- **Gentle and encouraging** — never clinical, pushy, or corporate.
- **Simple and clear** — short sentences, everyday words. Avoid academic or overly formal phrasing.
- **Mindful and reflective** — the text often pauses to acknowledge feelings. Preserve that rhythm.

## Do Not Translate (preserve exactly as-is)

- **Brand / product names:** Garmin, Garmin Connect, Connect IQ
- **App name:** "Meditation & Breathwork" — translate naturally into the target language (e.g., DE: "Meditation & Atemübungen", FR: "Méditation & Respiration"). Use the most natural, idiomatic phrasing. Keep the `&` separator.
- **Technical acronyms:** HRV, RMSSD, SDRR, pNN20, pNN50, bpm
- **URLs and links:** all `https://...` URLs, Markdown link targets
- **Markdown anchors:** all `<a id="..."></a>` values and `#anchor` references in links
- **YAML front matter keys:** `layout`, `title`, `subtitle`, `permalink`, `share-title`, `share-description` — translate only the **values**
- **Code/technical identifiers:** setting names shown in code-like contexts
- **Proper names:** Florian Geigl, Cory Muscara

## Glossary (key terms — use consistently within each language)

| English                      | Guidance                                                                                                                                                                                |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| session                      | A single meditation or breathwork run. Use the most natural equivalent (e.g., DE: "Session", FR: "session", JA: "セッション", KO: "세션", ZH: "练习" or "课程").                        |
| breathwork                   | Structured breathing exercises. Use the established wellness term in each language (e.g., DE: "Atemarbeit" or "Atemübungen", FR: "exercices de respiration" or "travail respiratoire"). |
| nervous system               | Use the standard physiological term (e.g., DE: "Nervensystem", ES: "sistema nervioso").                                                                                                 |
| regulation / regulated state | Emotional/nervous-system regulation — not rules or government.                                                                                                                          |
| stress                       | As a physiological signal, not general life stress. Keep lowercase unless sentence-initial.                                                                                             |
| heart rate variability       | Spell out on first use, then use "HRV" throughout.                                                                                                                                      |
| tracking                     | In the context of observing/recording physiological data — not surveillance.                                                                                                            |
| mindfulness / awareness      | Choose the most natural, non-academic equivalent.                                                                                                                                       |

## Cultural & Linguistic Adaptation

- **Translate meaning, not words.** If an English sentence structure sounds awkward in the target language, restructure it. Prioritize how a native speaker would naturally express the same idea.
- **Adapt idioms, metaphors, and humor.** For example, _"Sneaky little mind"_ should become a culturally equivalent playful expression, not a literal translation.
- **Keep the informal, friendly address** appropriate to each language:
  - DE: use "du" (informal)
  - FR: use "tu" (informal)
  - ES: use "tú" (informal, Latin America + Spain friendly)
  - PT: use "você" (Brazilian Portuguese)
  - UK: use informal "ти"
  - JA: use polite-informal (です/ます form, avoid keigo)
  - KO: use polite-informal (해요체)
  - ZH: use direct, conversational tone (你)

## Language-Specific Notes

- **Japanese (ja):** Use です/ます for instructions, casual tone for reflective passages. Use full-width punctuation (。、「」). Avoid excessive katakana where native terms exist.
- **Korean (ko):** Use 해요체 (polite-informal). Use native Korean words where possible over Sino-Korean.
- **Chinese Simplified (zh):** Use full-width punctuation (。，、""）. Keep sentences concise — Chinese favors shorter clauses.
- **Ukrainian (uk):** Use informal "ти". Follow modern Ukrainian orthography.
- **Portuguese (pt):** Target Brazilian Portuguese (most Garmin users in Portuguese-speaking markets).
- **French (fr):** Use "tu" for the personal, friendly feel. Follow metropolitan French conventions.

---

## Store description translation rules (`generated/ConnectIQStore/MeditateStoreDescription-*.txt`)

- Translate the English Garmin app store description into the target language.
- Output must be a plain `.txt` file — no Markdown.
- Preserve paragraph breaks and line breaks as in the original.
- You may freely restructure sentences for natural reading flow.
- The result should read like it was written by a native speaker for that app store — not like a translation.

## User guide translation rules (`generated/UserGuides/UserGuide-*.md`)

- Translate the English Markdown user guide into the target language.
- Preserve all Markdown structure: headings, lists, code blocks, links, anchor tags, and emphasis.
- Preserve `permalink` values exactly as-is (they are URL paths, not translatable text).
- You may restructure sentences and paragraphs for clarity and natural flow.
- The guide has a supportive, reassuring tone — maintain that emotional quality throughout.

## Advertisement translation rules (`generated/Advertisements/Advertisement-*.md`)

- Translate the English Markdown advertisement page into the target language.
- Preserve all Markdown structure: headings, lists, code blocks, links, and emphasis.
- YAML front matter: keep keys as-is, translate only the values (except `layout` and `permalink` which stay in English).
- You may restructure sentences for persuasive, natural flow.
- The ad blends emotional appeal with practical information — preserve both qualities.

## General

- Produce polished, publication-ready text. Each translation should read as if a native speaker wrote it from scratch.
- Do not add extra commentary, translator notes, or wrap the output in code fences.
- Maintain consistent terminology within each language across all three files (store description, user guide, advertisement).
