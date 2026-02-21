---
summary: "Agent requirements questionnaire for custom OpenClaw flavors"
read_when:
  - Defining a custom agent use case
  - Scoping event promo or social marketing automation
title: "Agent Requirements Questionnaire"
---

# Agent Requirements Questionnaire

Please answer the questions below in this file. Short answers are fine; for complex answers you can add notes or examples. At the top, please fill the three quick decisions so I can prioritize next steps.

---

## Quick decisions

- Preferred channels to connect (choose one or more): CLI, Web UI, WhatsApp
- File & command access level: read-only repo & files / allow command execution (safe sandbox) / full shell access
- Persistent background service: yes / no

---

## A) Goals & Scope

1. Primary goal: SEO/facebook marketing/social-media agent, umbrella personal agent, or both? (Prioritize if "both")
2. Top 3 tasks you want automated

   - Content ideation and drafting for social (X/LinkedIn/short-form scripts).
   - Research + summarization (competitor monitoring, topic research, keyword ideas).
   - Light dev/devops support (repo-aware code assistance, simple CI checks or task automation).

3. Fully autonomous vs Assistant-only (needs approval)

   - **Fully autonomous**:
     - Daily/weekly research jobs (e.g., "monitor these sites/accounts and summarize").
     - Drafting content into a local queue or file (not posting).
     - Helpful comments on facebook?
   - **Assistant-only (needs approval)**:
     - Posting to social platforms.
     - Making code changes, opening PRs, or running non-trivial scripts.
     - Any action that spends money, edits production systems, or sends messages to other humans.

---

## B) Data & Knowledge

4. Data sources: Local repo and local files (event assets, notes), Google Drive (event docs), and the event landing page copy. Later: connect Facebook/youtube once the core agent works.
5. Are there private datasets or PII the agent will handle? Not in scope right now.
6. Storage preference: on-device only (no cloud)

---

## C) Channels & UX

7. Preferred interaction modes: Chat-style conversation (WhatsApp and web UI), scheduled digests (daily event-promo tasks), and occasional CLI commands when I'm in dev mode.
8. Should the agent be able to post directly to social platforms? Yes, but only to event promo channels and only in defined time windows. Start with draft-only mode, then allow direct posting once templates are validated.
9. Preferred persona/brand voice (short description or example tone): Warm, hopeful, community-focused, but still clear and factual about colon cancer awareness. Avoid fearmongering; emphasize empowerment, early screening, and local community support.

---

## D) Permissions & Safety

10. Allow shell command execution? Yes, but limited to my OpenClaw and event-related repos (no system-wide commands, no sudo). Primarily for pulling latest content, generating assets, or running small scripts.
11. Risky action approvals: Two-step approval for anything public-facing (social posts, emails, DMs). Single approval for internal actions (updating local files, generating drafts).
12. Logging & audit: Store full logs locally on my laptop. Include a human-readable audit trail of all public-facing actions (what was posted, where, and when).

---

## E) Automation & Scheduling

13. Scheduling needs

    - **Daily**:
      - Morning: "event promo task list" (what to post, where, suggested captions).
      - Evening: short recap of what was posted and engagement highlights.
    - **Weekly**:
      - Summary of growth (followers, engagement, clicks if available).
      - Suggestions for the coming week's content based on what worked.

14. Posting windows / quiet hours / rate limits?

    - Posting windows: 9am–9pm local time, with preference for lunchtime and early evening.
    - Quiet hours: no posting or messaging 9pm–8am.
    - Rate limits: start with up to 3 posts per day per platform plus up to 5 replies/comments.

15. Failure handling: Retry transient failures up to 3 times with backoff. If a job fails repeatedly, pause that job, log the error, and send me a brief explanation plus next-step suggestions.

---

## F) Integrations & Tools

16. Which third-party APIs will you provide keys for (list): LLM provider(s), WhatsApp/WhatsApp bridge, Facebook, and optionally X and LinkedIn. Optionally: Google Analytics/Search Console or link-tracking service for the landing page if possible?
17. Need browser automation: Yes, to handle platforms or pages without good APIs (e.g., posting on certain social sites, checking event listing pages, or grabbing metrics dashboards).
18. Analytics integrations required (GA, Meta, X analytics, other): If possible, connect to Google Analytics or link-tracking for the event page, plus any available social analytics (Instagram/Facebook/X). Use them mainly for weekly summaries and basic A/B comparisons.

---

## G) Models & Compute

- **Local vs remote**: Use remote APIs for main reasoning and copywriting; optionally experiment with a small local model for simple, offline tasks like reorganizing notes or generating checklists.
- **Latency vs cost**: Balanced. Interactive chat should feel responsive; scheduled jobs can favor lower cost over speed.
- **Fine-tuning**: Start with prompts and retrieval using my event docs, landing page, and brand notes. Revisit fine-tuning only if the project becomes long-term and patterns stabilize.

---

## H) Evaluation & Metrics

- **Success KPIs**:
  - Ticket registrations or concrete actions driven from the event link.
  - Reach and engagement on event-related posts.
  - My time saved on writing, scheduling, and monitoring.
- **Evaluation cadence**: Weekly checks on engagement and tasks completed. One deeper review after the event to see what worked and what to change next time.

---

## I) Testing, CI & Safety Tests

- **Tests**: Yes. Include unit tests for key actions (posting, scheduling, summarizing) and a "dry run" mode that shows proposed posts without sending them.
- **Gate for live posting**: Manual opt-in per-post at first. Later, I may move to a daily opt-in list (approve a batch of posts each morning).

---

## J) Deployment & Ops

- **Run method**: Manual dev-run while I'm building, then a user-level background service on my laptop so it can handle scheduled tasks even when I'm not watching.
- **Backup & restore**: Local backups of config, agent state, and vector indexes (e.g., daily or weekly snapshots). Optionally sync encrypted backups to cloud storage if needed later.
- **Multi-device sync**: Not required right now. Nice-to-have later so I can migrate to a server or second machine without losing memory.

---

## K) Maintenance & Governance

- **Who can change config**: Me only, at least for this event campaign.
- **Update policy**: Manual review and update. Lock versions during the event; only update dependencies or models if there's a critical fix or clear benefit.

---

## L) Misc

- **Offline capability**: Basic drafting and working with local files should work offline (e.g., writing posts, planning tasks). Anything involving APIs or posting waits until I'm online.
- **UI preferences**: Simple chat UI with clear history, plus an easy way to view "scheduled posts", "past posts", and "ideas backlog". Ability to export conversations and content plans as markdown.
- **Legal/regulatory concerns**: Be careful about medical claims: stick to reputable sources and avoid giving personal medical advice. Focus on awareness, screening recommendations from trusted guidelines, and event logistics, and keep privacy in mind for any attendee data.
