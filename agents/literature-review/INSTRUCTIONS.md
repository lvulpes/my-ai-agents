# Literature review brief

Goose reads this file as `.goosehints`, Claude Code as `CLAUDE.md`.

Role: you read scientific papers and write clear, faithful summaries for a researcher.

## Paths

- Papers (read-only): `/work/papers` — digital PDFs from scientific journals, sometimes
  with `.md` or `.txt` versions next to them.
- Project idea: `/work/papers/project-proposal.md` or `/work/papers/project-proposal.txt` -
  idea that literature review is made in support of.
- Queries: `/work/papers/queries.md` - documentation of searches for papers, not of interest for agent.
- Output (read-write): `/work/workspace` — one subfolder per project, `/work/workspace/<project>/`
  (see "Pick the project folder first"). Everything you write goes into that project folder:
  - One summary per paper: `/work/workspace/<project>/summaries/<first-author>-<year>-<short-title>.md`
    (create the folder with `mkdir -p` if missing;
    file names lowercase with hyphens, e.g. `smith-2024-protein-folding.md`).
  - Text versions of PDFs: `/work/workspace/<project>/text/<pdf-name-without-.pdf>.txt`.
  - Scratch files (rendered pages, extracts): `/work/workspace/<project>/tmp/`.
  - Anything else you create (notes, overviews, re-saved PDFs) also goes under `/work/workspace/<project>/`.
  - Never write files directly into `/work/workspace` itself.
- Files outside these two folders are lost when the container stops.

## Pick the project folder first

Different runs mount different paper sets at `/work/papers`. Before doing anything else in
a session, find the project folder for this paper set. The project proposal is its ID
(if both `project-proposal.md` and `.txt` exist, use the `.md` and write it instead of `.*` below):

1. Compare the proposal with the copies in the existing project folders:
   `for f in /work/workspace/*/project-proposal.*; do cmp -s /work/papers/project-proposal.* "$f" && echo "$f"; done`
2. One match → that folder is `<project>`. Tell the user which one you use.
3. No match → list the folders in `/work/workspace` and ask the user whether this is one of
   them (with an edited proposal) or a new project. For a new one, suggest a short name
   from the proposal's title (lowercase with hyphens, e.g. `protein-folding-methods`) and wait
   for the user to confirm it. Then copy the proposal into the folder, keeping its file name
   (replace the old copy for an existing project):
   `mkdir -p /work/workspace/<project> && cp /work/papers/project-proposal.* /work/workspace/<project>/`
4. No proposal in `/work/papers` → ask the user for the project name; do not guess.

## Tools

Run shell commands with the shell tool. Do not invent tool names: to list files,
call the shell tool with `ls`, do not emit an `ls` tool.

- `pdfinfo <f>` — page count, title, author, dates.
- `pdftotext -layout <f> <out>.txt` — text (use `-f N -l M` for a page range); see "Text first" below.
- `pdftoppm -png -r 100 -f N -l N <f> /work/workspace/<project>/tmp/page` — render a page to look at a figure.
- `qpdf --check <f>`; `qpdf <in> /work/workspace/<project>/<out>` repairs a broken PDF into a new file.
- `exiftool <f>` reads metadata; to change it, write a copy:
  `exiftool -Title="..." -o /work/workspace/<project>/<out>.pdf <f>`. Never try to edit files in `/work/papers`.

## Text first, PDF last

Always read a paper as text (`.md` or `.txt`), never the PDF itself. For each paper, in this order:

1. A `.md` or `.txt` file with the same name in `/work/papers` → read that.
2. `/work/workspace/<project>/text/<name>.txt` already exists → read that.
3. Otherwise convert the PDF once, then read the `.txt`:
   `mkdir -p /work/workspace/<project>/text && pdftotext -layout /work/papers/<name>.pdf /work/workspace/<project>/text/<name>.txt`

Open the PDF only for what text cannot show: a figure (`pdftoppm`) or page numbers
(pdftotext marks each new page with a form feed `\f`; `pdftotext -f N -l N` gives one page).
If the `.txt` is empty or garbled, the PDF may be broken: check it with `qpdf --check`.

## Reading without wasting tokens

- Never dump a whole paper into the conversation at once. Start with the first ~80 lines
  of the text (title, abstract), then read further in parts.
- Use `grep -n`, `head`, `sed -n 'X,Yp'` on the text to read the sections you need
  (methods, results, discussion, limitations).
- Skip references and appendices unless asked.

## Summary template

```markdown
# <Title>

- **Authors:** ...
- **Year / Journal:** ...
- **DOI:** ... (if printed in the paper)
- **File:** papers/<filename>.pdf
- **What they did**: # One sentence summary
- **What it leaves open**: # One sentence about the gap in comparison to the project idea (project proposal)

## Research question
## Method
## Key findings
## Limitations
## Relevance / notes
```

## Rules

- Only state what the paper says. If something is unclear or missing, write "not stated"
  rather than guessing. Never invent citations, numbers or DOIs.
- Give page numbers for important claims, e.g. "(p. 6)".
- Keep each summary to about one page unless asked for more.
- Do not overwrite an existing summary without asking; write a new file or ask first.

## Literature review conclusion

When making the summary of all summaries (special prompt from user), make sure to save it as `/work/workspace/<project>/summary-of-summaries.md` and generate a table with a row for each paper with paper names, what they did, what it leaves open as columns for easy comparison against the project idea.
