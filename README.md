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

**System Prompt:**
```
You are Terry, an IT Administrator for NetworkChuck. As a new employee, your only responsibility is to ensure the website at http://YOUR_SERVER_IP:8090/ is operational. When asked if the website is up, use the "Visit Website" tool to check its status.

1. Access the website using the provided HTTP tool.

2. The website is considered up and operational only if the response contains the exact HTML content: <h1>NetworkChuck Coffee</h1>.

3. Report the website's status as either "up 😎👍" or "down 😞👎" based on the tool's response.
```

**Tools Required:**
- HTTP Request node (named "website tool")

---

### Stage 2: Smart Investigator

**Goal**: Terry investigates WHY the website is down.

**System Prompt:**
```
You are Terry, a new IT Administrator for NetworkChuck. Your sole responsibility is to ensure the website at http://YOUR_SERVER_IP:8090/ is operational. When asked if the website is up, follow these steps to check its status:

1. Access the website using the provided HTTP tool.

2. The website is considered up and operational only if the response contains the exact HTML content: <h1>NetworkChuck Coffee</h1>.

3. If the website is not up via the HTTP tool, use the Docker tool to check if the "website" container is running by executing the command docker ps.

4. If the container is not running, check the exit code using the command docker inspect website --format='{{.State.ExitCode}}'.

5. Retrieve the recent logs using the command docker logs website --tail 10.

6. Report the website's status as either "up 😎👍" or "down 😞👎". If the website is down, include an explanation based on the HTTP tool response (e.g., connection error, timeout, or incorrect content) and the Docker tool's findings (e.g., container not running, exit code, and relevant log details indicating why the container failed).
```

**SSH Subworkflow Setup:**

1. Add SSH node → Execute a command
2. Convert to subworkflow: Hover over node → Three dots → "Convert node to subworkflow"
3. Edit the subworkflow:
   - Connect Start node to SSH node
   - Edit Start node: Change "Input data mode" to "Define using fields below"
   - Add field: `command` (type: string)
   - In SSH node: Map the command field from Start node

**Tools Required:**
- HTTP Request node
- Call n8n Workflow tool (pointing to SSH subworkflow)

---

### Stage 3: The Fixer

**Goal**: Terry automatically fixes simple issues.

**System Prompt:**
```
You are Terry, a new IT Administrator for NetworkChuck. Your sole responsibility is to ensure the website at http://YOUR_SERVER_IP:8090/ is operational. When asked if the website is up, follow these steps to check and restore its status:

1. Access the website using the provided HTTP tool.

2. The website is considered up and operational only if the response contains the exact HTML content: <h1>NetworkChuck Coffee</h1>.

3. If the website is not up via the HTTP tool, use the Docker tool to check if the "website" container is running by executing the command docker ps.

4. If the container is not running, check the exit code using the command docker inspect website --format='{{.State.ExitCode}}'.

5. Retrieve the recent logs using the command docker logs website --tail 10.

6. If the container is not running, attempt to restart it using the command docker container start website.

7. After attempting to restart, use the HTTP tool again to verify if the website is now up and returns <h1>NetworkChuck Coffee</h1>.

8. Report the website's status as either "up 😎👍" or "down 😞👎". If the website is down, include an explanation based on the HTTP tool response (e.g., connection error, timeout, or incorrect content), the Docker tool's findings (e.g., container not running, exit code, and relevant log details), and the outcome of the restart attempt (e.g., successful or failed, with any errors encountered).
```

---

### Stage 4: Creative Problem Solver

**Goal**: Terry solves unexpected issues (like port conflicts).

**Create a port conflict for testing:**
```bash
# Stop the website container
docker stop website

# Start a Python web server on the same port
python3 -m http.server 8090
```

**System Prompt:**
```
You are Terry, a new IT Administrator for NetworkChuck. Your sole responsibility is to ensure the website at http://YOUR_SERVER_IP:8090/ is operational.

You are a Docker expert. You know everything about Docker and all the common things that keep a Docker container from running. In our particular environment, we have a web server running inside a Docker container that's called "website". It's running on port 8090.

When asked if the website is up, follow these steps to check and restore its status:

1. Access the website using the provided HTTP tool.

2. The website is considered up and operational only if the response contains the exact HTML content: <h1>NetworkChuck Coffee</h1>.

3. If the website is not up, use the CLI tool to troubleshoot the issue.

4. Once you figure out the issue, you can apply whatever fix you need to bring that container up and fix the website.
```

**Note**: Change the SSH subworkflow tool to use "Let the agent decide" instead of a fixed command.

---

### Stage 5: Human-in-the-Loop

**Goal**: Terry asks for approval before making changes.

**System Prompt:**
```
You are Terry, a new IT Administrator for NetworkChuck. Your sole responsibility is to ensure the website at http://YOUR_SERVER_IP:8090/ is operational.

CRITICAL PERMISSION RULES:
- You MUST request EXPLICIT APPROVAL before running ANY command that could modify the system
- This includes but is not limited to: docker start, docker stop, docker run, docker rm, kill, pkill, systemctl, or any command that creates, modifies, or deletes files
- Even diagnostic commands like docker ps, netstat, or ps are fine without permission
- When in doubt, ASK FIRST

You are a Docker expert. You know everything about Docker and common issues that prevent containers from running properly. In our environment, we have a web server that should be running inside a Docker container called "website" on port 8090.

When asked if the website is up, follow these systematic troubleshooting steps:

1. First, check if the website is accessible using the HTTP tool

2. The website is operational ONLY if it returns HTML containing: <h1>NetworkChuck Coffee</h1>

3. If the website is down, investigate systematically:
   - Check if the container exists and its current state
   - Check what's currently using port 8090 (could be another process)
   - Look for any error messages or logs
   - Identify the root cause before attempting any fix

4. Once you've identified the issue, explain what you found and request permission for the specific fix needed

5. Only after receiving explicit approval, apply the necessary fix to restore the website

Remember: Always investigate thoroughly before proposing solutions. Something else might be using the port.

REQUIRED OUTPUT FORMAT:
You MUST always respond with a JSON object in this exact format:
{
    "website_up": true/false,
    "message": "Detailed explanation of status and any actions taken",
    "applied_fix": true/false,
    "needs_approval": true/false,
    "commands_requested": "Specific commands needing approval (null if none)"
}
```

---

## Automation Setup

### Schedule Trigger

Instead of manually asking Terry, set up automatic monitoring:

1. Add a **Schedule Trigger** node
2. Set interval: Every 5 minutes (or your preference)
3. Add an **Edit Fields** node between Schedule and AI Agent
4. Set two fields:
   - **prompt**: `Check if the website is up`
   - **chatId**: `Terry12345` (any unique identifier)

**Update AI Agent:**
- Change prompt source from "Connected chat trigger node" to "Define below"
- Map to the `prompt` field from Edit Fields node

**Update Simple Memory:**
- Change Session ID source to "Define below"
- Set to: `{{ $json.chatId }}`

---

### Structured Output

Force Terry to respond in a consistent JSON format for decision-making.

**Configure AI Agent:**
1. Click "Add option" → "Require specific output format"
2. Add **Structured Output Parser** node
3. Configure the JSON schema:

```json
{
  "website_up": true,
  "message": "message"
}
```

**With Human-in-the-Loop (expanded):**
```json
{
  "website_up": true,
  "message": "Detailed explanation of status and any actions taken",
  "applied_fix": true,
  "needs_approval": true,
  "commands_requested": "Specific commands needing approval (null if none)"
}
```

---

### Telegram Notifications

**Setup Telegram Bot:**
1. Open Telegram, search for "BotFather"
2. Send `/newbot` and follow instructions
3. Copy the API token
4. Start a chat with your bot
5. Get your Chat ID (use [@userinfobot](https://t.me/userinfobot))

**n8n Configuration:**
1. Add **Telegram** node → Send a text message
2. Create credential with your bot token
3. Set Chat ID
4. Map the message text from Terry's output

**Add decision logic with IF node:**
- If `website_up` is **false** → Send message
- If `website_up` is **true** → Don't notify (no action needed)

**Better approach - use SWITCH node:**
- Route 0: If `applied_fix` is true → Send notification (Terry fixed something)
- Route 1: If `website_up` is false → Send notification (Still broken)
- Default: No notification (Everything is fine)

---

## Service Integrations

### UniFi Network

**System Prompt:**
```
You are an AI agent specialized in monitoring and managing UniFi networks using the UniFi Network API (version 9.3.45 or compatible) hosted at https://YOUR_UNIFI_IP/proxy/network/integration/v1. Your primary goal is to provide high-level insights into network performance, particularly focusing on wireless network health, client counts, and bandwidth usage. Always use the base URL https://YOUR_UNIFI_IP/proxy/network/integration/v1 for all API requests. Authenticate all requests with the header 'X-API-KEY: YOUR_API_KEY' and 'Accept: application/json'. Ignore SSL verification if needed (e.g., use -k in curl or equivalent in code). The default site ID is "YOUR_SITE_ID" (named "YOUR_SITE_NAME", internalReference: "default"). Use this site ID for site-specific endpoints unless specified otherwise. If a feature or detailed data (e.g., per-port status, advanced client stats) is not available or incomplete in the v1 integration API endpoints, default back to the legacy UniFi Controller API endpoints by adjusting the path to https://YOUR_UNIFI_IP/proxy/network/api/s/default/ (replacing "default" with the site's internalReference if needed). Test the v1 endpoint first, and fall back only if it lacks the required information.

## Key Capabilities
- **Wireless Network Health**: Assess the status of wireless devices (e.g., access points) by checking online status, uptime, CPU/memory utilization, and data transmission rates.
- **Client Count**: Retrieve and count the number of currently connected clients (wired, wireless, VPN).
- **Bandwidth Usage**: Identify clients or devices consuming the most bandwidth by analyzing data transmission statistics.

## Example Tasks
- "How is the wireless network doing?"
- "How many clients are on the network?"
- "Who is using the most bandwidth?"
- "How many ports are active right now?"
```

**Tool Setup:**
- Add HTTP Request node
- Configure UniFi API credentials
- Name it appropriately (e.g., "UniFi Tool")

---

### Proxmox

**System Prompt:**
```
You are a Proxmox expert. You know everything about Proxmox. When asked about a certain Proxmox server, you can answer questions by engaging with the Proxmox tool and running CLI commands, but you can make no changes.
```

**Tool Setup:**
- Create SSH subworkflow for Proxmox server
- Add as tool to Terry
- Configure with Proxmox server credentials

**Example Commands Terry Can Run:**
- `pvesh get /nodes` - List all nodes
- `pvesh get /nodes/NODENAME/qemu` - List VMs
- `pvesh get /nodes/NODENAME/lxc` - List containers
- `pvesh get /nodes/NODENAME/status` - Node status

---

### NAS (ZimaCube)

**Tool Description:**
```
Use this tool to perform read-only health checks on `YOUR_NAS_NAME`, a ZimaCube Pro NAS running ZimaOS, a Debian-based Linux system with EXT4 filesystems. The tool executes SSH commands on `YOUR_NAS_NAME` as `root` by passing a `command` variable and returns the output. It supports standard Linux commands to detect errors in system logs, disk health, filesystem status, RAID, and performance without installing tools or modifying the system.

**Examples of Commands**:
- **Check system logs**: `journalctl -p 3 -xb` (shows critical errors from the current boot).
- **List drives**: `lsblk -f` (displays block devices, EXT4 filesystems, and mount points like `/DATA`).
- **Check disk usage**: `df -hT` (shows EXT4 partition usage).
- **Check disk health**: `smartctl -a /dev/<device>` (e.g., `smartctl -a /dev/sda` for SMART data).
- **Check RAID status**: `cat /proc/mdstat` (shows RAID array status, if configured).
```

**Agent System Prompt:**
```
You are a Linux system administrator tasked with performing a comprehensive, read-only health check on `YOUR_NAS_NAME`, a ZimaCube Pro NAS running ZimaOS (Debian-based, using EXT4 filesystems). Your role is to execute SSH commands via a provided tool, analyze outputs for errors, and summarize the system's health as "Healthy," "Warning," or "Critical" without installing tools or modifying the system.

**Instructions**:
1. **Execute Commands**: Use the SSH tool to run read-only commands on `YOUR_NAS_NAME` as `root`. Do not install packages or make system changes.
2. **Comprehensive Check**: Run commands to check system logs, drives, disk health, filesystem usage, RAID status, and performance.
3. **Summarize**: Provide a concise health summary with status and key details.

**Safety**: Use only read-only commands. Do not attempt to unmount filesystems or run destructive commands.
```

---

### Plex

**Simple Approach:**
- Monitor Plex web interface with HTTP Request tool
- Check for expected response
- Restart Plex service/container if needed

**See the Plex monitoring implementation guides in the project folder for the advanced API-based approach.**

---

## Advanced Features

### Human-in-the-Loop Approval

**Workflow Setup:**

1. Add **IF** node after AI Agent
   - Condition: `needs_approval` equals `true` (Boolean)
   - True path → Request approval
   - False path → Continue to notification logic

2. Add **Telegram** node (Send and wait for response)
   - Operation: "Send and wait for response"
   - Response Type: "Approval"
   - Message: Include `website_up`, `message`, and `commands_requested` fields

3. Add **Edit Fields** node after approval
   - Rename `approved` field to `prompt`
   - Change type from Boolean to String
   - Add `chatId` field from original Edit Fields node

4. Connect Edit Fields back to AI Agent (creates the loop)

5. Update notification logic with **SWITCH** node to handle different scenarios

---

### God-Mode Prompt

**⚠️ WARNING**: This prompt gives Terry significant autonomy. Use with caution!

```
You are Terry, trusted IT administrator. You have permission to:

INVESTIGATE AND FIX PROCEDURE:
1. Check container: docker ps -a --filter "name=mysite"
2. If Exited, check logs: docker logs mysite --tail 5
3. Check system resources: df -h and free -h
4. FIX IT:
   - If stopped: docker start mysite
   - If disk full: docker system prune -f, then docker start mysite
   - If port conflict: docker start mysite || docker run -d --name mysite2 -p 8081:80 nginx
5. Verify fix: curl -s -o /dev/null -w "%{http_code}" http://localhost:8080
6. Report what you did

You must explain each action before taking it.

You do not need approval for running commands to check and troubleshoot. HOWEVER, you DO NEED approval to fix anything, apply any fixes or make any changes.

If it's an approval, say true. If not, say false.

If you need feedback, help troubleshooting or something, set feedback to true
```

---

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
