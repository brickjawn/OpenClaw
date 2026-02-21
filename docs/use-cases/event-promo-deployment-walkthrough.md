---
title: "Event Promo Deployment Walkthrough"
description: "Full deployment walkthrough for the Louder Than Cancer event promo flavor: install, onboard, configure, add cron jobs, verify, and back up."
summary: "Full deployment walkthrough for Louder Than Cancer event promo flavor"
read_when:
  - Deploying the event promo custom flavor
  - Setting up local laptop with user-level background service
  - Following specialist-coordinated deployment checklist
---

# Event Promo Deployment Walkthrough

This walkthrough implements the Project Review and Deployment plan, coordinating IT Project Manager, Integration Specialist, Cybersecurity Specialist, and DevOps Engineer inputs for the Louder Than Cancer custom flavor.

<Info>
**Scope** (from [Agent Requirements](/agent-requirements)): Local laptop, user-level background service (systemd/launchd), on-device storage only.
</Info>

## Prerequisites

- Node 22+
- OpenClaw installed (`npm install -g openclaw@latest` or installer script)
- LLM API key (Anthropic, OpenAI, etc.)
- Optional: WhatsApp bridge token or QR

---

## Phase 1: Install and workspace (~15 min)

<Steps>
  <Step title="Install OpenClaw">
    <Tabs>
      <Tab title="macOS/Linux">
        ```bash
        curl -fsSL https://openclaw.ai/install.sh | bash
        ```
      </Tab>
      <Tab title="npm">
        ```bash
        npm install -g openclaw@latest
        ```
      </Tab>
    </Tabs>
  </Step>

  <Step title="Ensure event-promo-workspace exists">
    Path: `~/Projects/OpenClaw/event-promo-workspace` or `~/event-promo-workspace`.

    Required contents:
    - `skills/event-promo/`
    - `skills/content-drafting/`
    - `skills/research-summary/`
    - `system-prompt-louder-than-cancer.md`
  </Step>

  <Step title="Add event content">
    Place event docs in `event-docs/` and assets in `assets/`.
  </Step>
</Steps>

---

## Phase 2: Onboarding (~20 min)

<Steps>
  <Step title="Run onboarding wizard">
    ```bash
    openclaw onboard --install-daemon
    ```

    <Check>
    The wizard configures auth, gateway port (18789), and optional channels.
    </Check>
  </Step>

  <Step title="Follow wizard prompts">
    - **Auth**: Select LLM provider and add API key
    - **Gateway**: Port 18789, bind loopback (for local)
    - **Optional**: Add WhatsApp channel if desired
  </Step>

  <Step title="Verify gateway">
    ```bash
    openclaw gateway status
    ```
  </Step>
</Steps>

---

## Phase 3: Flavor config (~15 min)

<Steps>
  <Step title="Edit openclaw.json">
    Edit `~/.openclaw/openclaw.json`:

    - Set `agents.list[0].workspace` to the absolute path of `event-promo-workspace`
    - Add bindings for `web` and optionally `whatsapp`

    ```json openclaw.json
    {
      "agents": {
        "list": [
          {
            "id": "main",
            "default": true,
            "workspace": "/home/user/Projects/OpenClaw/event-promo-workspace"
          }
        ],
        "bindings": [
          { "agentId": "main", "match": { "channel": "web" } },
          { "agentId": "main", "match": { "channel": "whatsapp" } }
        ]
      }
    }
    ```
  </Step>

  <Step title="Copy exec approvals">
    ```bash
    cp event-promo-workspace/exec-approvals.example.json ~/.openclaw/exec-approvals.json
    ```
  </Step>

  <Step title="Edit allowlist paths">
    In `~/.openclaw/exec-approvals.json`, replace:
    - `~/event-promo-workspace` with your actual workspace path
    - `~/Projects/your-event-repo` with your event repo path
  </Step>

  <Step title="Restart gateway">
    ```bash
    openclaw gateway restart
    ```
  </Step>
</Steps>

---

## Phase 3.5: Team sync (optional, ~5 min)

<Info>
**Skip this phase** if your team does not use shared OneDrive for event docs (flyers, survey data, meeting notes). If you do, this lets the agent index those files for morning digest and recap tasks.
</Info>

<Steps>
  <Step title="Add memorySearch.extraPaths">
    In `~/.openclaw/openclaw.json`, under `agents.defaults`, add or extend `memorySearch.extraPaths`:

    ```json
    "memorySearch": {
      "extraPaths": ["~/.openclaw/team_sync"]
    }
    ```
  </Step>

  <Step title="Add sync cron job">
    Run `scripts/sync_data.sh` before the morning digest so the agent sees fresh OneDrive content. Add a cron job (e.g. 8am):

    ```bash
    # Example: 8am, before 9am morning digest
    0 8 * * * /path/to/OpenClaw/scripts/sync_data.sh
    ```

    Default: syncs `~/OneDrive/LouderThanCancer` → `~/.openclaw/team_sync`. Override with `TEAM_SYNC_SOURCE` and `TEAM_SYNC_DEST` if needed.
  </Step>
</Steps>

See [Docker: laptop data layout](/install/docker-laptop-data) and [Event Promo Setup](/use-cases/event-promo-setup) for details.

---

## Phase 4: Cron jobs (~10 min)

<Info>
Ensure the gateway is running and `cron.enabled: true` in config (default).
</Info>

<Steps>
  <Step title="Add morning job (9am)">
    ```bash
    openclaw cron add \
      --name "event-promo-morning" \
      --cron "0 9 * * *" \
      --tz "America/New_York" \
      --session isolated \
      --message "Generate today's event promo task list: what to post, where, suggested captions. Output to chat." \
      --announce \
      --channel last
    ```
  </Step>

  <Step title="Add evening job (9pm)">
    ```bash
    openclaw cron add \
      --name "event-promo-evening" \
      --cron "0 21 * * *" \
      --tz "America/New_York" \
      --session isolated \
      --message "Short recap of what was posted today and engagement highlights." \
      --announce \
      --channel last
    ```
  </Step>

  <Step title="Add weekly job (Monday 9am)">
    ```bash
    openclaw cron add \
      --name "event-promo-weekly" \
      --cron "0 9 * * 1" \
      --tz "America/New_York" \
      --session isolated \
      --message "Weekly summary: growth, engagement, suggestions for next week's content." \
      --announce \
      --channel last
    ```
  </Step>

  <Step title="Verify jobs">
    ```bash
    openclaw cron list
    openclaw cron run <job-id>   # Test one job manually
    ```
  </Step>
</Steps>

<Tip>
Adjust `--tz` to your timezone. Use `--channel last` to deliver to your last-used channel.
</Tip>

---

## Phase 5: Verification (~10 min)

<Steps>
  <Step title="Check gateway and channels">
    ```bash
    openclaw status --deep
    ```
  </Step>

  <Step title="Open Control UI">
    ```bash
    openclaw dashboard
    ```
  </Step>

  <Step title="Test event-promo skill">
    In the chat, type: "Generate today's event promo task list"

    <Check>
    The agent should use the event-promo skill and output a task list.
    </Check>
  </Step>

  <Step title="Test cron job">
    ```bash
    openclaw cron run <job-id>
    ```
  </Step>
</Steps>

---

## Phase 6: Backup (optional, ~5 min)

Per [Agent Requirements](/agent-requirements): local backups of config, agent state, and vector indexes.

<Tabs>
  <Tab title="Backup script (recommended)">
    From repo root:

    ```bash
    ./scripts/backup-openclaw.sh        # Config, cron, exec-approvals
    ./scripts/backup-openclaw.sh --full # Also full ~/.openclaw tarball to ~/openclaw-full-*.tar.gz
    ```
  </Tab>
  <Tab title="Manual backup">
    ```bash
    mkdir -p ~/.openclaw/backups
    cp ~/.openclaw/openclaw.json ~/.openclaw/backups/openclaw-$(date +%Y%m%d).json
    tar -czvf ~/openclaw-backup-$(date +%Y%m%d).tar.gz ~/.openclaw
    ```
  </Tab>
</Tabs>

<Tip>
Schedule via cron or run manually weekly.
</Tip>

---

## Pre-deployment checklists

<AccordionGroup>
  <Accordion title="Integration Specialist">
    - [ ] Agent config points to `event-promo-workspace` (absolute path)
    - [ ] Bindings: `main` agent for `web` and `whatsapp` (if used)
    - [ ] Cron scheduler enabled (`cron.enabled: true`)
    - [ ] Skills discoverable in workspace
  </Accordion>

  <Accordion title="Cybersecurity Specialist">
    - [ ] API keys in env or secure config (not in repo)
    - [ ] Gateway token set
    - [ ] Exec approvals: `security: allowlist`, paths limited to workspace and repos
    - [ ] No posting without approval (draft-first in skills)
    - [ ] Run `pnpm audit` before push; address moderate+ findings
    - [ ] `~/.openclaw/` and workspace dirs have restrictive permissions (e.g. 700)
  </Accordion>

  <Accordion title="DevOps Engineer">
    - [ ] Daemon installed and running
    - [ ] Health: `openclaw gateway status`, `openclaw status --deep`
    - [ ] Cron jobs added and verified
    - [ ] Backup procedure documented and tested
  </Accordion>
</AccordionGroup>

---

## Health checks

| Command | Purpose |
|---------|---------|
| `openclaw gateway status` | Daemon running |
| `openclaw status --deep` | Gateway and channels |
| `openclaw doctor` | Config and state repair |
| `openclaw cron list` | Jobs scheduled |

---

## Rollback

1. `openclaw gateway stop` – stop daemon
2. Restore `~/.openclaw/openclaw.json` from backup
3. `openclaw cron delete <id>` for each job
4. Restore `exec-approvals.json` if changed

---

## Modes of action

| Mode | When | Action |
|------|------|--------|
| **Dev** | Building, testing | Run `openclaw gateway --port 18789 --verbose` in foreground; no daemon |
| **Staging** | Pre-event validation | Daemon and cron; dry-run only; no live posting |
| **Live** | Event campaign (March 2025) | Daemon and cron; manual approve per post; audit trail |
| **Post-event** | After March 27 | Review engagement; lock versions; optional cloud backup |

---

## Related docs

<CardGroup cols={2}>
  <Card title="Event Promo Setup" icon="gear" href="/use-cases/event-promo-setup">
    Config, cron, and exec approvals reference.
  </Card>
  <Card title="Agent Requirements" icon="clipboard-list" href="/agent-requirements">
    Questionnaire and scope.
  </Card>
  <Card title="Getting Started" icon="rocket" href="/start/getting-started">
    General OpenClaw setup.
  </Card>
</CardGroup>
