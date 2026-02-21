---
name: event_promo
description: Event promotion and social marketing tasks—task lists, drafts, posting windows, and engagement recaps.
metadata:
  {
    "openclaw": {
      "emoji": "📣",
      "requires": {}
    }
  }
---

# Event Promo

Event promotion and social marketing for awareness campaigns (e.g., colon cancer awareness, community events).

## When to use (trigger phrases)

Use this skill immediately when the user asks any of:

- "event promo task list"
- "what to post today"
- "draft event content"
- "event promo task list for today"
- "what should I post"
- "generate today's event promo"
- "morning task list" (in event context)
- "evening recap" (in event context)
- "weekly summary" (in event context)

## Voice and tone

- **Warm, hopeful, community-focused**—clear and factual about awareness topics
- **Avoid fearmongering**—emphasize empowerment, early screening, and local community support
- **Stick to reputable sources**—no personal medical advice; focus on trusted guidelines and event logistics
- **Privacy**—keep attendee data private

## Posting rules

- **Posting windows**: 9am–9pm local time only; prefer lunchtime and early evening
- **Quiet hours**: No posting or messaging 9pm–8am
- **Rate limits**: Up to 3 posts per day per platform; up to 5 replies/comments per day
- **Draft-first**: Use `message` tool with `dryRun: true` for drafts. Do not post live without explicit user approval
- **Two-step approval**: Any public-facing post (social, email, DM) requires manual opt-in before sending

## Output locations

- Drafts: Write to `drafts/` in the workspace (e.g., `drafts/2025-02-20-morning-captions.md`)
- Audit: Append all public-facing actions (what, where, when) to `audit.log` in the workspace
- Task lists: Output to chat or to `drafts/` as markdown

## Tools

- **message** (with `dryRun: true`): Generate draft posts; never send without approval
- **bash**: Only for allowlisted paths (workspace, event repos)—pull content, generate assets, run small scripts
- **browser**: For platforms without good APIs (posting, checking event pages, metrics dashboards)

## Failure handling

- Retry transient failures up to 3 times with backoff
- If a job fails repeatedly: pause that job, log the error, and send a brief explanation plus next-step suggestions to the user
