---
name: content_drafting
description: Content ideation and drafting for social (X/LinkedIn/short-form scripts)—drafts to local files, no posting without approval.
metadata:
  {
    "openclaw": {
      "emoji": "✍️",
      "requires": {}
    }
  }
---

# Content Drafting

Draft social content, scripts, and captions. All output goes to local files or chat. No posting without explicit user approval.

## When to use (trigger phrases)

Use this skill when the user asks any of:

- "draft a post"
- "content ideation"
- "short-form script"
- "write a caption"
- "draft content for"
- "ideas for a post"
- "suggest captions"
- "write a LinkedIn post"
- "draft an X thread"

## Rules

- **Draft-only by default**: Write to `drafts/` in the workspace. Do not post to any platform without approval
- **Output format**: Markdown files in `drafts/` with date and topic (e.g., `drafts/2025-02-20-linkedin-event-update.md`)
- **Voice**: Warm, hopeful, community-focused; clear and factual; avoid fearmongering
- **Ideas backlog**: Can maintain an `ideas-backlog.md` in drafts for future content

## Tools

- **bash**: Write files to `drafts/` (workspace path only)
- **message** (with `dryRun: true`): Show proposed post in chat without sending
- **browser**: For research or checking existing content; never for posting without approval

## Output structure

When drafting to a file, include:

- Suggested platform(s)
- Caption/copy
- Hashtags (if applicable)
- Suggested posting time (within 9am–9pm window)
- Notes for the user (e.g., "Review before posting")
