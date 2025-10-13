
# n8n AI Agent (Terry) — Full Self-Hosted Bundle

Everything you need to run n8n and Terry (Stages 1–5 + Full HITL).

## Quick Start
1) `cp .env.example .env` and set strong secrets.
2) `./scripts/start.sh` then open `http://<server_ip>:5678`
3) Import JSONs from `workflows/`
4) Create credentials: OpenAI, Telegram, SSH.
5) Run `./scripts/demo_website.sh` for the test page on port 8090.

## Workflows Included
- Stage 1–5 (monitor → investigator → fixer → creative → HITL)
- Subflow — SSH Exec
- Telegram Notify Example
- **Terry — Full HITL Workflow (Schedule + Telegram)** ← recommended end-to-end

## Environment
Set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` in `.env`, then restart compose.

## Backups
`./scripts/backup.sh` creates a dated tarball of data + config.
