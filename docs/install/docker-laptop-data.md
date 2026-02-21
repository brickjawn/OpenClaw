---
summary: "Laptop Docker layout with WhatsApp, Teams, and a single data directory"
read_when:
  - You run the gateway in Docker on your own laptop
  - You want WhatsApp (and maybe Teams) as channels with OneDrive as the knowledge base
  - You want a single bind-mounted data directory you can back up or move
title: "Docker: laptop data layout"
---

## When to use this

Use this guide when:

- You run the OpenClaw gateway in Docker on your **laptop** (not a VPS).
- Your **Dev/Marketing** team already lives in **Microsoft Teams + OneDrive**.
- The rest of the team talks in **WhatsApp**, and you want them to query a shared bot there.
- You want a **single data directory** on disk that contains:
  - Gateway state and logs.
  - A synced subset of OneDrive (your knowledge base).
  - Any content you choose to ingest from WhatsApp.

If you just need a generic containerized gateway, see [Docker](/install/docker) instead.

## Big picture: layers

Think of three layers on your laptop:

- **Host (laptop)**
  - Holds the `openclaw` repo.
  - Holds a single data directory (for example `~/Projects/openclaw/openclaw-data/`).
  - Runs Docker, browsers, OneDrive sync client, and any OCR/ingestion helpers.
- **Docker container (gateway + agent)**
  - Runs the OpenClaw gateway.
  - Sees only what you bind-mount into it.
  - Uses a single state directory (inside the container) for config, credentials, logs, media, and memory index.
- **External services**
  - LLM/embeddings APIs.
  - **WhatsApp** (via your phone + web-style bridge).
  - **Microsoft Teams + OneDrive** as the team’s source of truth.

At runtime:

- You and your team chat with the bot on **WhatsApp** (and optionally Teams).
- The gateway runs in a **Docker container** on your laptop.
- The container’s state directory lives inside your **host `openclaw-data`** folder.
- The agent uses a **knowledge base** built from a **synced subset of OneDrive** plus any content you ingest from WhatsApp.

## Directory layout on your laptop

From your host’s point of view, a simple layout under your existing repo:

```text
~/Projects/openclaw/              # this repo
~/Projects/openclaw/openclaw-data/  # single data directory (bind-mounted into Docker)
  openclaw.json                     # gateway config (created by onboarding)
  agents/                           # per-agent state (created by gateway)
  memory/                           # memory index SQLite files
  logs/                             # gateway logs
  media/                            # inbound/outbound media cache (per channels)
    inbound/                        # WhatsApp and other inbound media (binary)
  workspace/                        # agent workspace (files, AGENTS.md, MEMORY.md, etc.)
  onedrive-sync/                    # subset of OneDrive synced for RAG
  whatsapp/                         # optional: exports / OCR output / curated ingest from WhatsApp
  credentials/                      # provider credentials (includes WhatsApp creds)
  ...                               # other state the gateway manages
```

Key points:

- `openclaw-data` is the **state directory** (`OPENCLAW_STATE_DIR` inside the container).
- `workspace/` is the **agent workspace** mounted as `/data/workspace` inside the container.
- `media/inbound/` is where the gateway already saves **inbound media** (including WhatsApp attachments).
- `onedrive-sync/` is your **synced subset of OneDrive** – the main knowledge base.
- `whatsapp/` is where you can place **WhatsApp-derived content you want indexed** (for example, exports, OCR output, or summaries the agent writes).

You decide what flows into `onedrive-sync/` and `whatsapp/`; the agent just sees files on disk.

## Minimal Docker Compose (single data directory)

From the repo root (`~/Projects/openclaw`), create or update your `docker-compose.yml` to use a single bind mount for `openclaw-data`:

```yaml
services:
  openclaw-gateway:
    image: ${OPENCLAW_IMAGE:-openclaw:local}
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN}
      OPENCLAW_STATE_DIR: /data
      OPENCLAW_WORKSPACE_DIR: /data/workspace
    volumes:
      - ./openclaw-data:/data
    ports:
      - "18789:18789"
      - "18790:18790"
    init: true
    restart: unless-stopped
    command:
      [
        "node",
        "dist/index.js",
        "gateway",
        "--bind",
        "lan",
        "--port",
        "18789",
      ]

  openclaw-cli:
    image: ${OPENCLAW_IMAGE:-openclaw:local}
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN}
      OPENCLAW_STATE_DIR: /data
      OPENCLAW_WORKSPACE_DIR: /data/workspace
      BROWSER: echo
    volumes:
      - ./openclaw-data:/data
    stdin_open: true
    tty: true
    init: true
    entrypoint: ["node", "dist/index.js"]
```

Notes:

- `./openclaw-data:/data` makes the **entire state directory** live inside `openclaw-data` on your laptop.
- Inside the container:
  - Config lives at `/data/openclaw.json`.
  - Logs live under `/data/logs/`.
  - Memory index lives under `/data/memory/`.
  - Media cache (including WhatsApp inbound media) lives under `/data/media/`.
  - Workspace is `/data/workspace`.
- You can still use `./docker-setup.sh` to build the image and set up tokens; just make sure the env vars you use in Compose (`OPENCLAW_STATE_DIR`, `OPENCLAW_WORKSPACE_DIR`) match this layout.

## Configure the knowledge base (OneDrive)

In this model, **OneDrive is the primary knowledge base**. The rest of the team continues to work in Teams + OneDrive as usual; you only sync the pieces the bot needs.

1. **Choose the subset to sync**
   - Example: an “Events” folder with flyers, FAQs, sponsor decks, and timelines.
2. **Sync it into `onedrive-sync/`** (or `team_sync/`)

   **Option A — OneDrive client or rclone**

   Use the official OneDrive sync client or a tool like `rclone` to keep a local mirror of that subset at:
   - `~/Projects/openclaw/openclaw-data/onedrive-sync/`

   **Option B — rsync from OneDrive mount**

   If OneDrive is already synced locally (e.g. `~/OneDrive/`), use `scripts/sync_data.sh` to rsync into a separate folder. rsync only transfers changed file parts, which is efficient for teams that frequently update event docs.

   ```bash
   # Default: ~/OneDrive/LouderThanCancer → ~/.openclaw/team_sync
   ./scripts/sync_data.sh

   # Custom paths
   TEAM_SYNC_SOURCE=~/OneDrive/Events TEAM_SYNC_DEST=~/Projects/openclaw/openclaw-data/team_sync ./scripts/sync_data.sh
   ```

   Add a cron job to run before your morning agent task (e.g. `0 8 * * *`).

3. **Tell OpenClaw to index it**
   - In your config (`openclaw-data/openclaw.json`), add the sync folder as an **extra memory path**:

```json5
{
  agents: {
    defaults: {
      memorySearch: {
        extraPaths: [
          "~/Projects/openclaw/openclaw-data/onedrive-sync",
          "~/.openclaw/team_sync"
        ]
      }
    }
  }
}
```

Use `onedrive-sync` if you use the OneDrive client or rclone directly; use `team_sync` if you use `scripts/sync_data.sh` to rsync from a OneDrive mount.

Behavior:

- OpenClaw watches `extraPaths` for **Markdown files** and maintains a vector index over them.
- When teammates ask questions on WhatsApp, the bot can retrieve relevant snippets from those docs and answer using that context.

Important:

- Only **Markdown** is indexed. PDFs, PowerPoint decks, and images must be converted to text/Markdown first (either manually or with a separate OCR/export step).

## Ingestion from WhatsApp

WhatsApp plays two roles:

- **Channel**: your team chats with the bot there.
- **Ingestion source**: you can feed the bot content via WhatsApp and make it part of the knowledge base.

### Where WhatsApp media goes

When you send media or documents to the gateway via WhatsApp, OpenClaw:

- Saves inbound media into the **media directory** under the state dir:

```text
openclaw-data/media/inbound/...
```

This is a **binary cache**, not directly indexed by memory search.

### Making WhatsApp content part of the KB

To make WhatsApp-derived content searchable:

- **Option 1: Export + OCR to Markdown**
  - Export PDFs or images that arrive on WhatsApp.
  - Run your own OCR or conversion step to generate `.md` files.
  - Save those `.md` files into:
    - `openclaw-data/whatsapp/` (recommended for WhatsApp-specific material), or
    - a subdirectory under `onedrive-sync/` if it belongs in the broader OneDrive knowledge base.
  - Ensure the directory you use is included in `memorySearch.extraPaths`.

- **Option 2: Agent-written summaries**
  - Ask the bot on WhatsApp to **summarize and store** important messages or documents.
  - The agent can:
    - Append notes to `MEMORY.md`, or
    - Write `.md` files into the workspace (for example, `workspace/memory/YYYY-MM-DD.md`).
  - Those files are automatically picked up by memory search.

Either way, the end state is the same: **Markdown in a path that memory search indexes**.

### Suggested config for WhatsApp ingest

Example `memorySearch` config that treats OneDrive + WhatsApp exports as indexed sources:

```json5
{
  agents: {
    defaults: {
      memorySearch: {
        extraPaths: [
          "~/Projects/openclaw/openclaw-data/onedrive-sync",
          "~/Projects/openclaw/openclaw-data/whatsapp"
        ]
      }
    }
  }
}
```

You can keep `onedrive-sync` and `whatsapp` as separate folders so you can change how you sync or back them up independently.

## Team workflow on WhatsApp

With this setup, the team uses WhatsApp to:

- **Query the knowledge base**
  - “What is the FAQ for the Louder Than Cancer event?”
  - “Summarize the sponsor levels for next month’s event.”
  - “What are the key deadlines from the timeline doc?”
- **Analytics and reporting**
  - “Summarize engagement over the last N posts.”
  - “Draft a report for the Dev/Marketing team based on recent notes.”
- **Posting and content drafts**
  - “Draft a WhatsApp broadcast about early screening.”
  - “Create a Teams announcement using the latest sponsor info.”
- **Ingestion commands**
  - “Ingest this PDF and add it to the Louder Than Cancer docs.”
  - “Summarize this image and save it to memory.”

When teammates send files to the bot:

- The gateway saves the raw media under `media/inbound/`.
- You (or a small scheduled script) can:
  - Move or copy them into `whatsapp/` or `onedrive-sync/`.
  - Run OCR/export to create `.md` files alongside the originals.
- Memory search sees the new Markdown and starts using it in answers.

## Day in the life (end-to-end)

One full loop for a WhatsApp-centric workflow:

1. **Morning sync**
   - Your OneDrive client or `rclone` syncs the “Events” folder into `openclaw-data/onedrive-sync/`.
   - Any new or changed Markdown files are indexed by the gateway’s memory search.
2. **Team member sends a PDF on WhatsApp**
   - The PDF is delivered to the bot.
   - The gateway saves it to `openclaw-data/media/inbound/...`.
3. **Ingestion**
   - You (or a script) pick up that PDF from `media/inbound/`, run OCR to produce `event-faq.md`, and save it into `openclaw-data/whatsapp/` or a subfolder under `onedrive-sync/`.
   - Because `whatsapp/` and `onedrive-sync/` are in `memorySearch.extraPaths`, the new Markdown is indexed.
4. **Query**
   - Later, someone in the team asks on WhatsApp: “What are the key points from the latest Louder Than Cancer FAQ?”
   - The agent:
     - Uses memory search over `onedrive-sync/` + `whatsapp/`.
     - Retrieves relevant chunks from the new `.md` files.
     - Calls the LLM with that context and returns a focused answer.
5. **Follow-up content**
   - The same conversation can then ask: “Draft a broadcast message based on that FAQ,” or “Write a Teams announcement using the same info.”

All of this state lives under `openclaw-data`, so moving to another machine or a VPS is:

- Copy `openclaw-data` to the new host.
- Reuse the same `docker-compose.yml`.
- Point your DNS or clients at the new gateway.

## Summary

- **One data directory**: `openclaw-data` is your single bind-mounted state dir.
- **OneDrive = knowledge base**: sync a curated subset into `onedrive-sync/` and index it.
- **WhatsApp = channel + ingest**: team chats and sends content there; inbound media is saved under `media/inbound/`, and you decide what to convert to Markdown and index via `whatsapp/` (or back into `onedrive-sync/`).
- **Easy migration**: copy `openclaw-data` and reuse the same Docker Compose on another machine.

