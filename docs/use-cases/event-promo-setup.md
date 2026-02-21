---
title: "Event Promo Setup"
description: "Configure OpenClaw for event promotion and social marketing: agent config, cron jobs, exec approvals, and dry-run posting."
summary: "Setup guide for event promo and social marketing flavor"
read_when:
  - Configuring OpenClaw for event promotion
  - Setting up cron jobs for daily/weekly tasks
  - Configuring exec approvals for workspace-only access
---

# Event Promo Setup

This guide configures OpenClaw for event promotion and social marketing (e.g., colon cancer awareness, community events). It uses the [Agent Requirements Questionnaire](/agent-requirements), the `event-promo-workspace/` directory (see repo root), and custom skills.

<Info>
For a full step-by-step deployment (install, onboard, flavor config, cron, verification, backup), see [Event Promo Deployment Walkthrough](/use-cases/event-promo-deployment-walkthrough).
</Info>

## Prerequisites

- OpenClaw installed and gateway running
- WhatsApp channel configured (optional; Web UI works without it)
- Workspace at `event-promo-workspace/` (or your chosen path)

---

## 1. Agent config

Point your agent to the event promo workspace:

```json openclaw.json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "workspace": "<path-to-event-promo-workspace>"
      }
    ],
    "bindings": [
      { "agentId": "main", "match": { "channel": "whatsapp" } },
      { "agentId": "main", "match": { "channel": "web" } }
    ]
  }
}
```

<Tip>
Replace `<path-to-event-promo-workspace>` with the absolute path (e.g. `~/event-promo-workspace` or `./event-promo-workspace` if running from the repo root).
</Tip>

---

## 2. Cron jobs

Add daily morning, evening, and weekly jobs. Adjust `--tz` to your timezone. Use `--channel last` to deliver to your last-used channel, or `--channel web` / `--channel whatsapp` if configured.

<Steps>
  <Step title="Add morning task list (9am)">
    ```bash
    openclaw cron add \
      --name "event-promo-morning" \
      --cron "0 9 * * *" \
      --tz "America/Los_Angeles" \
      --session isolated \
      --message "Generate today's event promo task list: what to post, where, suggested captions. Output to chat." \
      --announce \
      --channel last
    ```
  </Step>

  <Step title="Add evening recap (9pm)">
    ```bash
    openclaw cron add \
      --name "event-promo-evening" \
      --cron "0 21 * * *" \
      --tz "America/Los_Angeles" \
      --session isolated \
      --message "Short recap of what was posted today and engagement highlights." \
      --announce \
      --channel last
    ```
  </Step>

  <Step title="Add weekly summary (Monday 9am)">
    ```bash
    openclaw cron add \
      --name "event-promo-weekly" \
      --cron "0 9 * * 1" \
      --tz "America/Los_Angeles" \
      --session isolated \
      --message "Weekly summary: growth, engagement, suggestions for next week's content." \
      --announce \
      --channel last
    ```
  </Step>

  <Step title="Verify jobs">
    ```bash
    openclaw cron list
    openclaw cron run <job-id>   # Run a job immediately for testing
    ```
  </Step>
</Steps>

---

## 3. Exec approvals

Create or edit `~/.openclaw/exec-approvals.json` to restrict shell commands to your workspace and event repos:

```json exec-approvals.json
{
  "version": 1,
  "defaults": {
    "security": "allowlist",
    "ask": "on-miss",
    "askFallback": "deny",
    "autoAllowSkills": false
  },
  "agents": {
    "main": {
      "security": "allowlist",
      "ask": "on-miss",
      "askFallback": "deny",
      "autoAllowSkills": true,
      "allowlist": [
        { "pattern": "~/event-promo-workspace/**", "id": "workspace" },
        { "pattern": "~/Projects/OpenClaw/**", "id": "openclaw-repo" },
        { "pattern": "~/Projects/your-event-repo/**", "id": "event-repo" }
      ]
    }
  }
}
```

Replace paths with your actual workspace and repo paths. The agent can run commands only in these directories.

<Warning>
Never add `sudo` or system-wide paths to the allowlist. Keep scope limited to workspace and event repos.
</Warning>

---

## 4. Dry run for posting

- **Skill instructions**: The event-promo and content-drafting skills require `dryRun: true` for drafts. Live posting needs explicit user approval.
- **CLI test**: `openclaw message send --dry-run --target <recipient> --message "Test"` prints the payload without sending.
- **Manual opt-in**: Start with per-post approval; later you can move to a daily batch approval list.

---

## 5. Audit trail

The event-promo skill instructs the agent to append public-facing actions to `audit.log` in the workspace. Ensure the workspace path is writable.

Example `audit.log` entries:

```
2025-02-20 14:30 - Draft posted to Facebook (dry-run, not sent)
2025-02-20 15:00 - Post approved and sent to Facebook event page
```

---

## Quick test

<Steps>
  <Step title="Open Control UI">
    ```bash
    openclaw dashboard
    ```
  </Step>

  <Step title="Test event-promo skill">
    In the chat, type: "Generate today's event promo task list"
  </Step>

  <Step title="Verify output">
    The agent should use the event-promo skill and output a task list.
  </Step>

  <Step title="Test cron job">
    ```bash
    openclaw cron run <job-id>
    ```
  </Step>
</Steps>

---

## Troubleshooting

<AccordionGroup>
  <Accordion title="Skills not loading">
    Ensure `agents.list[].workspace` points to the workspace containing `skills/event-promo/`, etc. Restart the gateway after config changes.
  </Accordion>

  <Accordion title="Cron not running">
    Check `cron.enabled: true` in config. Run `openclaw cron list` to see job status.
  </Accordion>

  <Accordion title="Exec blocked">
    Add the command's resolved path to the allowlist in `exec-approvals.json`, or use the macOS app to approve.
  </Accordion>
</AccordionGroup>

---

## Related docs

<CardGroup cols={2}>
  <Card title="Event Promo Deployment Walkthrough" icon="rocket" href="/use-cases/event-promo-deployment-walkthrough">
    Full install-to-deploy workflow.
  </Card>
  <Card title="Agent Requirements" icon="clipboard-list" href="/agent-requirements">
    Questionnaire and scope.
  </Card>
</CardGroup>
