---
name: prose-check
description: Remove AI writing tells from prose before sending it or after writing it. Use for commit messages, PR titles and bodies, issue comments, and doc or README edits. Keeps every fact; changes wording and shape only.
---

# Prose check

Remove AI writing tells without changing what the text says. Work from the text you have; add no facts, names, numbers, or quotes.

## Process

1. Scan the text once and note each tell by its name below.
2. Rewrite the affected sentences or paragraphs. Keep code, commands, paths, links, identifiers, and quoted material unchanged.
3. Rescan the rewrite for the strongest tells. Then return only the final text for commit and PR text. For a file edit, write the final text and skip the report.

## Strongest tells: act on one sighting

- Contrast framing: "not X but Y", "it's not just X, it's Y". State Y directly.
- Staged closer: a one-line fragment or summary that repeats the point ("Simple. Effective.").
- Run-up: a sentence that announces the point ("Let's dig into what matters here.").
- Deep-sounding saying: an aphorism in place of a fact.
- Arguing with no one: "Some people think X." when nobody did.

## Rhythm

- Forced triads: three parallel adjectives or examples where two or one fit.
- The same sentence opener repeated across a paragraph or section.
- Dashes as the default connector. Use a period, comma, or parentheses.
- Stacked qualifiers ("often, in many cases, potentially").
- Hyphenated pairs applied everywhere.
- Passive voice or a missing subject when the actor is known.

## Inflation

- Stock words: delve, crucial, pivotal, robust, seamless, leverage, showcase, underscore, tapestry.
- Inflated significance: "marks a pivotal moment", "a testament to".
- Vague association: "reflecting broader trends", "in the wider ecosystem".
- Trailing -ing rider: "..., highlighting the importance of X".
- Sales language and unsourced authority ("experts agree").
- Avoiding is/are/has: "serves as", "boasts", "features".

## Formatting

- Bold on every list item, or bold as decoration.
- Decorative headings and title case where the surrounding text uses sentence case.
- Curly quotes in prose that is otherwise plain ASCII.

## Leftovers

- Chat residue: "Great question", "I hope this helps", "Let me know if".
- Knowledge-limit disclaimers or guesses ("as of my last update").
- A heading repeated as the first sentence of its section.
- Describing the document ("This section explains...") instead of its subject.
- Re-explaining what the reader already has from the conversation or the diff.

## Leave alone

- Quotations, titles, proper names, and passages that discuss a phrase rather than use it.
- Voice: specific details, first-person choices, asides, and stated uncertainty.
- Commands, code, paths, and link targets.

For worked before-and-after examples, read the `humanizer` skill.
