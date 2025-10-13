# n8n AI Agent (Terry) - Complete Setup Guide

> **Video**: n8n Now Runs My ENTIRE Homelab
> **Part 2**: Building Terry - Your AI IT Employee

This guide contains all the commands, prompts, and configurations shown in the video for setting up Terry, an intelligent AI agent that can monitor, troubleshoot, and fix issues in your homelab with human approval.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
  - [Demo Website Container](#demo-website-container)
  - [n8n Workflow Setup](#n8n-workflow-setup)
- [Terry's Evolution](#terrys-evolution)
  - [Stage 1: Basic Monitor](#stage-1-basic-monitor)
  - [Stage 2: Smart Investigator](#stage-2-smart-investigator)
  - [Stage 3: The Fixer](#stage-3-the-fixer)
  - [Stage 4: Creative Problem Solver](#stage-4-creative-problem-solver)
  - [Stage 5: Human-in-the-Loop](#stage-5-human-in-the-loop)
- [Automation Setup](#automation-setup)
  - [Schedule Trigger](#schedule-trigger)
  - [Structured Output](#structured-output)
  - [Telegram Notifications](#telegram-notifications)
- [Service Integrations](#service-integrations)
  - [UniFi Network](#unifi-network)
  - [Proxmox](#proxmox)
  - [NAS (ZimaCube)](#nas-zimacube)
  - [Plex](#plex)
- [Advanced Features](#advanced-features)
  - [Human-in-the-Loop Approval](#human-in-the-loop-approval)
  - [God-Mode Prompt](#god-mode-prompt)
- [Troubleshooting](#troubleshooting)

---

## Overview

Terry is an AI agent built with n8n that can:
- **Monitor** your services 24/7
- **Troubleshoot** issues by running diagnostic commands
- **Fix** problems with your explicit approval
- **Alert** you via Telegram/Slack when action is needed

**Philosophy**: You're training an employee, not programming a bot.

---

## Prerequisites

- n8n instance (cloud-hosted or self-hosted)
- Docker installed on your server
- OpenAI API key (or compatible LLM)
- Telegram account (for notifications)
- Optional: Twingate for secure remote access

---

## Initial Setup

### Base environment configuration

1. Copy the example configuration so Docker Compose can pick it up:

   ```bash
   cp .env.example .env
   ```

2. Review the following defaults that silence the runtime deprecation warnings shipped with recent n8n releases:

   - `N8N_RUNNERS_ENABLED=true` turns on the task runner infrastructure that will soon be enabled by default.
   - `OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true` ensures manual executions use workers when running in queue mode.
   - `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` keeps backwards-compatible access to environment variables from Code nodes and expressions. Flip this to `true` if you do **not** need that access.
   - `N8N_GIT_NODE_DISABLE_BARE_REPOS=true` proactively disables the legacy bare-repository support in the Git node.

   Adjust the values if your deployment needs different behaviour, then restart the stack to apply the changes.

### Demo Website Container

Create a simple nginx website for testing Terry's monitoring capabilities:

```bash
# Create a simple website container for demonstrations
# Using port 8090 to avoid conflicts with n8n/Traefik
docker run -d --name website -p 8090:80 nginx
docker exec website sh -c 'echo "<h1>NetworkChuck Coffee</h1>" > /usr/share/nginx/html/index.html'
```

**Test the website:**
```bash
# Replace with your server IP
curl http://YOUR_SERVER_IP:8090
```

### n8n Workflow Setup

1. Create a new workflow in n8n
2. Add a **Manual Trigger** node
3. Add an **AI Agent** node
4. Configure the AI Agent:
   - Chat Model: OpenAI GPT-4o-mini (or your preferred model)
   - Memory: Simple Memory (for conversation context)

---

## Terry's Evolution

### Stage 1: Basic Monitor

**Goal**: Terry checks if the website is up.

**Workflow export**: `workflows/terry_stage1_basic_monitor.json`

What you get out of the box:

- A **Manual Trigger** that lets you test the workflow on demand.
- A **Set** node that stores the website URL (`TERRY_WEBSITE_URL` env var or defaults to `http://localhost:8090`).
- A ready-to-use **Website Availability** tool based on the HTTP Request Tool node.
- An **OpenAI chat model** (default `gpt-4o-mini`) and **Simple Memory** node wired into an AI Agent with the full monitoring prompt.

Outputs are short status updates such as _“Website is up 😎👍 — HTTP 200 with the correct banner.”_

### Stage 2: Smart Investigator

**Goal**: Terry investigates **why** the website is down.

**Workflow export**: `workflows/terry_stage2_investigator.json`

Enhancements over Stage 1:

- Adds a **Homelab Shell Tool** (Call n8n Workflow Tool) that wraps the `subflow_ssh_exec.json` workflow so Terry can run read-only diagnostics (`docker ps`, `docker logs`, `df -h`, `free -h`, etc.).
- Expanded prompt that forces Terry to explain each step before running it and to summarise possible root causes with bullet points.

### Stage 3: The Fixer

**Workflow export**: `workflows/terry_stage3_fixer.json`

- Terry now drafts remediation plans and requests human approval before executing fix commands.
- The AI Agent runs with a slightly “smarter” OpenAI model (`gpt-4o`) and more memory to keep track of ongoing incidents.
- The Homelab Shell Tool is reused so Terry can run approved commands (for example `docker start website` or `docker system prune -f`).

### Stage 4: Creative Problem Solver

**Workflow export**: `workflows/terry_stage4_creative_solver.json`

- Adds a **Think** tool which nudges Terry to brainstorm and document alternative mitigation steps before touching the environment.
- Introduces a knowledge-base URL field so he can reference runbooks and suggest preventive improvements.
- Keeps the same investigation/fix pipeline while emphasising creative solutions and documentation updates.

### Stage 5: Human-in-the-Loop

**Workflow export**: `workflows/terry_stage5_hitl.json`

- Adds a **Cron schedule** so Terry runs automatically (defaults to every day at midnight—adjust after import).
- Uses the **Structured Output Parser** node to enforce JSON with keys such as `needs_approval`, `commands_to_run`, and `notification_message`.
- Includes two Telegram notification paths:
  - Approval requests: sends an actionable alert listing the exact commands Terry wants to run.
  - Routine status updates: summarises health checks and any remediation actions that were taken.
- Keeps the “explain-before-you-act” rule and sets `feedback` to `true` whenever Terry needs more guidance.

> ⚠️ **Human approval remains mandatory** — the workflows ship with approval hooks but the actual decision still depends on you reviewing the Telegram message or n8n execution log.

## Workflow Imports & Configuration

1. **Copy the workflow JSON files** (`workflows/*.json`) into your n8n instance via the *Import from file* dialog, **or** run `scripts/import_terry_workflows.sh` after the stack is up to batch-import everything with the `n8n import:workflow` CLI.
2. If you use the script, it copies the JSON exports into the mounted `data/import` folder and imports them with `--force`, so repeated runs update existing workflows rather than creating duplicates.
3. **Import the SSH subworkflow** (`workflows/subflow_ssh_exec.json`) first. It exposes an `executeWorkflowTrigger` and the SSH node that powers the Homelab Shell tool in Stages 2–5.
4. After import, open the subworkflow and set your actual SSH credentials (it ships with the placeholder `SSH (set me after import)`).
5. In each Terry workflow, edit the **Homelab Shell Tool** node and pick the subworkflow you just configured (or keep the embedded JSON if you prefer the portable version).
6. Update the **OpenAI** and **Telegram** credentials referenced in the workflow nodes.

### Environment variables

Populate these optional variables in your `.env` file (or directly in the Set node if you prefer hardcoded values):

| Variable | Purpose | Default |
| --- | --- | --- |
| `TERRY_WEBSITE_URL` | URL monitored by Terry | `http://localhost:8090` |
| `TERRY_TELEGRAM_CHAT_ID` | Chat/channel ID for Telegram notifications | _empty_ |

Without `TERRY_TELEGRAM_CHAT_ID`, Stage 5 will still run but the Telegram nodes will error until you fill in the chat ID.

### Scheduling tips

- The Stage 5 Cron node is set to run once per day at midnight so the JSON export stays broadly compatible. Open the node after import and pick your desired cadence (for example “every 10 minutes”).
- If you prefer to keep the pipeline fully manual during testing, simply disable the Cron node or use the **Execute Workflow** button to run ad-hoc checks.

## Troubleshooting

### Terry Stopped Working After Adding Schedule

**Issue**: Chat ID and prompt variables not set correctly.

**Solution**:
1. Add Edit Fields node between Schedule and AI Agent
2. Set `prompt` field with your monitoring instruction
3. Set `chatId` field with unique identifier
4. Update AI Agent to use these fields instead of Chat Trigger
5. Update Simple Memory to use `{{ $json.chatId }}`

### Too Many Iterations Error

**Issue**: Terry is running too many tool calls.

**Solution**:
1. Increase max iterations in AI Agent settings (default is 10)
2. Make prompts more specific to reduce trial-and-error
3. Upgrade to smarter model (GPT-4 instead of GPT-4-mini)

### Terry Isn't Asking for Approval

**Issue**: Permission rules not clear in prompt.

**Solution**:
1. Add explicit "CRITICAL PERMISSION RULES" section
2. Provide clear examples of commands requiring approval
3. Add structured output fields: `needs_approval`, `commands_requested`
4. Test with known scenarios

### n8n Container Fails with `EACCES` on `/home/node/.n8n/config`

**Issue**: The `n8n` container cannot create its configuration file because the bind-mounted `./data` directory is owned by `root` (or another user) on the host machine.

**Solution**:
1. The stack now includes a lightweight `n8n-volume-permissions` service that prepares the `./data` directory before the main n8n container starts. Simply running `docker compose up -d` will fix the permissions in most cases.
2. If your host uses different user or group IDs, set `N8N_DATA_UID`/`N8N_DATA_GID` in your `.env` file so the helper service (and scripts) know which ownership to apply.
3. If you still run into issues or prefer to fix things manually, run the helper script:

   ```bash
   sudo N8N_DATA_UID=1000 N8N_DATA_GID=1000 ./scripts/fix-volume-permissions.sh
   ```

   Adjust the UID/GID values to match your environment.
4. Start (or restart) the stack: `docker compose up -d`
5. Check the container logs again—`n8n` should now be able to persist its configuration without permission errors.

### Telegram Not Receiving Messages

**Issue**: Incorrect Chat ID or bot configuration.

**Solution**:
1. Verify bot token is correct
2. Ensure you've started a chat with your bot
3. Get Chat ID from @userinfobot
4. Test with "Execute node" to verify connection

### SSH Commands Failing

**Issue**: Subworkflow not configured correctly.

**Solution**:
1. Verify SSH credentials in subworkflow
2. Ensure Start node has `command` field defined
3. Check SSH node is mapping the command variable
4. Test with simple command like `hostname`

---

## Best Practices

1. **Start Simple**: Begin with basic monitoring, then add complexity
2. **Document Everything**: Keep notes of what Terry can access
3. **Test in Sandbox**: Use the demo website setup before connecting to production
4. **Use Human-in-the-Loop**: Always require approval for system-modifying commands
5. **Monitor Terry**: Set up alerts for when Terry takes actions
6. **Iterate Prompts**: Refine system prompts based on Terry's behavior
7. **Version Control**: Save different versions of your workflows
8. **Security First**: Use Twingate or VPN for remote access, never expose directly

---

## What's Next?

In Part 3, we'll build:
- **Multiple specialized agents** (Network Admin, Storage Expert, Linux Engineer)
- **Shared knowledge base** for documentation
- **Helpdesk system** for user-submitted tickets
- **Agent collaboration** for complex problems

---

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [OpenAI API Documentation](https://platform.openai.com/docs/)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Twingate Setup Guide](https://www.twingate.com/docs/)

---

## Support

Questions? Issues? Join the discussion:
- [NetworkChuck Discord](#)
- [GitHub Issues](#)

---

**Remember**: You're training an employee, not programming a bot. Give Terry context, teach him your processes, and build trust progressively.

Happy automating! ☕️
