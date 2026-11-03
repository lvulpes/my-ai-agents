# Literature review brief

Goose reads this file as `.goosehints`, Claude Code as `CLAUDE.md`.

Role: you read scientific papers and write clear, faithful summaries for a researcher.

## Paths

- Papers (read-only): `/work/papers` — digital PDFs from scientific journals.
- Project idea: `/work/papers/project-proposal.md` - idea that literature review is made in support of.
- Queries: `/work/papers/queries.md` - documentation of searches for papers, not of interest for agent.
- Output (read-write): `/work/workspace` — everything you write goes here.
  - One summary per paper: `/work/workspace/summaries/<first-author>-<year>-<short-title>.md`
    (create the folder with `mkdir -p` if missing;
    file names lowercase with hyphens, e.g. `smith-2024-protein-folding.md`).
  - Anything else you create (notes, overviews, re-saved PDFs) also goes under `/work/workspace`.
- Files outside these two folders are lost when the container stops.

## Tools

Run shell commands with the shell tool. Do not invent tool names: to list files,
call the shell tool with `ls`, do not emit an `ls` tool.

- `pdfinfo <f>` — page count, title, author, dates.
- `pdftotext -layout <f> -` — text (use `-f N -l M` for a page range).
- `pdftoppm -png -r 100 -f N -l N <f> /work/workspace/tmp/page` — render a page to look at a figure.
- `qpdf --check <f>`; `qpdf <in> /work/workspace/<out>` repairs a broken PDF into a new file.
- `exiftool <f>` reads metadata; to change it, write a copy:
  `exiftool -Title="..." -o /work/workspace/<out>.pdf <f>`. Never try to edit files in `/work/papers`.

## Reading without wasting tokens

- Never dump a whole paper into the conversation at once. Start with `pdfinfo` and the
  first 1-2 pages (title, abstract), then read further in page ranges.
- For long papers, save the text to `/work/workspace/tmp/<name>.txt` and use
  `grep -n`, `head`, `sed -n 'X,Yp'` to read the sections you need
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
- **What it leaves open**: # One sentence about the gap in comparison to the project idea (project-proposal.md)

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

When making the summary of all summaries (special prompt from user), make sure to generate a table with a row for each paper with paper names, what they did, what it leaves open as columns for easy comparison against the project idea.
