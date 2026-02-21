---
name: research_summary
description: Research and summarization—competitor monitoring, topic research, keyword ideas. Output to local notes; no posting.
metadata:
  {
    "openclaw": {
      "emoji": "🔍",
      "requires": {}
    }
  }
---

# Research & Summarization

Competitor monitoring, topic research, keyword ideas, and summarization. Research only; no posting or public actions.

## When to use (trigger phrases)

Use this skill when the user asks any of:

- "competitor monitoring"
- "topic research"
- "keyword ideas"
- "summarize this"
- "research"
- "monitor these sites"
- "what's trending in"
- "summarize overnight updates"
- "competitor analysis"
- "keyword research"

## Scope

- **Research only**: Summarize URLs, local files, and documents
- **Output**: Local notes in workspace (e.g., `event-docs/research-notes.md` or `drafts/research-2025-02-20.md`)
- **No posting**: Never post to social, send messages, or take public-facing actions
- **Sources**: Stick to reputable sources; avoid unverified claims

## Tools

- **summarize** (if installed): For URLs, PDFs, YouTube—`summarize "https://..." --model google/gemini-3-flash-preview`
- **bash**: Read files, run `summarize` CLI; only in workspace or allowlisted paths
- **browser**: For pages without good APIs (e.g., checking event listings, dashboards)
- **message**: Never use for posting; only for delivering research summaries to chat

## Output format

When saving research to a file:

- Date and topic
- Key findings (bullets)
- Sources (URLs or file paths)
- Suggested next steps or follow-up questions
- Keywords or themes (if keyword research)

## Daily/weekly research jobs

For scheduled research (e.g., "monitor these sites and summarize"):

- Run as cron or heartbeat-triggered jobs
- Output to `event-docs/daily-research-YYYY-MM-DD.md` or similar
- Include: what was monitored, summary, notable changes, recommendations
