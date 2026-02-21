# Security Audit Report

**Date:** 2026-02-21  
**Auditor:** Cybersecurity Specialist (automated scan)  
**Scope:** Full repository scan for secrets, loose ends, and integration safety

---

## Executive Summary

| Category | Status | Notes |
|----------|--------|-------|
| **Secrets** | ✅ Pass | No real credentials in repo; test tokens are obviously fake |
| **Config security** | ✅ Pass | Path traversal protection, symlink checks, host env blocking |
| **Documentation** | ⚠️ Minor gaps | Event-promo deployment walkthrough omits team_sync option |
| **sync_data.sh** | ⚠️ Low risk | Env-based paths; acceptable for trusted-operator use |

---

## 1. Secrets Management

### Findings

- **No real credentials** in source. Grep for `apiKey`, `token`, `password` patterns found only:
  - Test fixtures (e.g. `sk-minimax-test`, `xoxb-test-token`, `test-gateway-token-1234567890`)
  - Rule examples (cybersecurity-specialist.mdc shows BAD pattern for education)
  - Config resolution logic (reads from env/config, does not hardcode)

- **`.gitignore`** correctly excludes:
  - `.env`
  - `memory/`, `.agent/*.json`, `local/`
  - `apps/ios/fastlane/.env`
  - Credentials/memory note: "NEVER COMMIT"

- **`detect-secrets`** baseline present (`.secrets.baseline`, `.detect-secrets.cfg`). SECURITY.md instructs maintainers to run `detect-secrets scan --baseline .secrets.baseline`.

- **Credential storage** documented in `docs/gateway/security/index.md`:
  - WhatsApp: `~/.openclaw/credentials/whatsapp/<accountId>/creds.json`
  - Auth profiles: `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
  - These paths are outside the repo and not committed.

### Recommendation

- Run `detect-secrets scan --baseline .secrets.baseline` in CI and before releases.
- Keep API keys/tokens in env vars or `~/.openclaw`; never in config files committed to git.

---

## 2. Config & Path Security

### Config includes (`src/config/includes.ts`)

- **Path traversal**: Rejects paths outside config root (CWE-22).
- **Symlink bypass**: Resolves `realpathSync` and re-validates against root.
- **Depth limit**: `MAX_INCLUDE_DEPTH` prevents include bombs.

### Host env security (`src/infra/host-env-security.ts`)

- **Blocked keys**: `NODE_OPTIONS`, `NODE_PATH`, `BASH_ENV`, `PYTHONPATH`, `LD_*`, `DYLD_*`, etc.
- **PATH override**: Blocked for request-scoped overrides to protect command resolution.
- **Sanitization**: `sanitizeHostExecEnv` filters dangerous vars before exec.

### Recommendation

- No changes needed. Existing controls are appropriate.

---

## 3. sync_data.sh (scripts/sync_data.sh)

### Behavior

- Rsyncs from `TEAM_SYNC_SOURCE` (default: `~/OneDrive/LouderThanCancer`) to `TEAM_SYNC_DEST` (default: `~/.openclaw/team_sync`).
- Paths come from environment variables.
- Uses `rsync -av --delete`; no shell interpolation of path values.

### Risk assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Path injection via env | Low | Script runs in trusted-operator context (cron, manual). Attacker would need to control env of the process. |
| Path traversal (e.g. `DEST="../../../etc"`) | Low | User sets DEST; rsync would write to that path. Same trust boundary as above. |
| Secret leakage in logs | None | Script logs only source/dest paths, not credentials. |

### Recommendation

- **Current use**: Acceptable for event-promo and laptop workflows where the operator controls cron/env.
- **Optional hardening**: Add path validation (e.g. require DEST to be under `$OPENCLAW_STATE_DIR` or `$HOME`) if the script is ever exposed to less-trusted environments.

---

## 4. Loose Ends & Documentation

### Connected

- `event-promo-setup.md` → `event-promo-deployment-walkthrough.md` ✓
- `event-promo-workspace/README.md` → team sync, exec-approvals, Event Promo Setup ✓
- `docker-laptop-data.md` → `sync_data.sh`, `team_sync`, `extraPaths` ✓
- `docs/project-diary.md` exists ✓
- `scripts/backup-openclaw.sh` exists and is referenced in deployment walkthrough ✓

### Gap

- **Event Promo Deployment Walkthrough** does not mention the OneDrive/team_sync flow. Teams using shared OneDrive for event docs would benefit from an optional step (e.g. Phase 3.5) covering:
  - Running `scripts/sync_data.sh` via cron before morning digest
  - Adding `memorySearch.extraPaths` for `team_sync`

### Recommendation

- Add an optional "Team sync (OneDrive)" subsection to the deployment walkthrough, linking to `docker-laptop-data` and `event-promo-workspace/README.md`.

---

## 5. Dependency Security

- `pnpm audit` was run; results depend on current lockfile and network.
- SECURITY.md notes Node.js 22.12.0+ for CVE fixes (CVE-2025-59466, CVE-2026-21636).

### Recommendation

- Run `pnpm audit` regularly and before releases.
- Keep Node.js at or above the documented minimum.

---

## 6. Security Checklist Summary

| Check | Status |
|-------|--------|
| No hardcoded secrets in source | ✅ |
| .gitignore excludes .env, credentials | ✅ |
| detect-secrets baseline present | ✅ |
| Config includes path traversal protection | ✅ |
| Host env dangerous keys blocked | ✅ |
| Credential storage documented | ✅ |
| sync_data.sh risk assessed | ⚠️ Low (trusted operator) |
| Event-promo docs mention team_sync | ⚠️ Partial (README + docker-laptop-data; deployment walkthrough missing) |

---

## 7. Diary Entry (for project-diary.md)

```markdown
## [2026-02-21] - Security audit (Cybersecurity Specialist)

**Timestamp**: 2026-02-21
**Specialist**: Cybersecurity
**Type**: Security

### Change Description
Repository-wide security scan: secrets, config/path safety, sync_data.sh, documentation connectivity.

### Impact Assessment
- **System Stability**: No impact
- **Cost Impact**: None
- **Security Impact**: None (audit only; no vulnerabilities requiring immediate fix)
- **Performance Impact**: None

### Testing Performed
- Grep for credential patterns
- Review of config includes, host-env-security
- sync_data.sh path flow analysis
- Documentation link/coverage check

### Rollback Procedure
N/A (audit report only)

### Status
Completed

### Notes
- sync_data.sh: Low risk for trusted-operator use; optional path validation if exposure widens.
- Recommendation: Add team_sync step to event-promo deployment walkthrough.
```
