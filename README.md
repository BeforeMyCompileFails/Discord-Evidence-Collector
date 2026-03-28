# Discord Evidence Collector

**GitHub:** https://github.com/BeforeMyCompileFails/Discord-Evidence-Collector  
**Author:** https://github.com/BeforeMyCompileFails

**A toolkit for parents to collect and preserve digital evidence of online predatory behavior, harassment, or exploitation targeting minors on Discord — in a format accepted by law enforcement and courts.**

> This toolkit was created after a real case in which a parent successfully assisted a criminal investigation into online predatory behavior targeting their child. The collected evidence was accepted by Europol.
>
> I hope no parent ever needs this. But if you do — this toolkit is here for you.

---

## ⚠️ Important Warnings

- **Do NOT confront the perpetrator.** This will alert them and they may delete evidence.
- **Do NOT share evidence publicly** (social media, forums). This can compromise the investigation and may be illegal.
- **Contact law enforcement first** Always contact your local law informent. Visit a police station and tell them what has been going on.
- This toolkit collects data that your child's Discord account has access to. You will need your child's cooperation and login credentials.
- Using your child's account to collect evidence is legal in most jurisdictions when done by a parent/guardian, but laws vary. Consult a lawyer if unsure.
- **This tool does NOT hack Discord.** It only exports data your child's own account can already see.

---

## What This Toolkit Does

| Script | Purpose |
|--------|---------|
| `collect_evidence.bat` | One-time export of Discord channels/DMs to browsable HTML + JSON |
| `monitor.bat` | Continuous monitoring — captures new messages every few minutes |
| `refresh_and_download.ps1` | Downloads media files (videos, images) from Discord CDN before links expire |
| `sha256_verify.bat` | Generates cryptographic checksums for all evidence files (required for court) |

---

## Requirements

- Windows 10 or Windows 11
- Internet connection
- Your child's Discord account credentials (to obtain a token — see below)
- DiscordChatExporter CLI (see Setup below)

---

## Setup

### Step 1: Download DiscordChatExporter CLI

This toolkit depends on [DiscordChatExporter](https://github.com/Tyrrrz/DiscordChatExporter) by Tyrrrz (MIT License).

This repository is pinned to a **specific stable release** to ensure long-term compatibility.

Run `setup\download_dce.bat` — it will automatically download the correct version into the `tools\` folder.

Or download manually:
1. Go to: https://github.com/Tyrrrz/DiscordChatExporter/releases/tag/2.43.3
2. Download `DiscordChatExporter.CLI.zip`
3. Extract into a folder called `tools\` inside this repository

Your folder structure should look like:
```
discord-evidence-collector\
├── tools\
│   └── DiscordChatExporter.Cli.exe   ← must be here
├── scripts\
│   ├── collect_evidence.bat
│   ├── monitor.bat
│   ├── refresh_and_download.ps1
│   └── sha256_verify.bat
├── setup\
│   └── download_dce.bat
└── README.md
```

---

### Step 2: Get Your Discord Token

A Discord **token** is like a master key to an account. You will use your child's token to export their messages.

> ⚠️ **Never share a Discord token with anyone.** Treat it like a password. Anyone with the token can access the account. Delete it from the script files after you are done.

**How to get the token (with your child's help):**

1. Open **Discord in a web browser** (https://discord.com/app) — log in with your child's account
2. Press **F12** on your keyboard (or right-click anywhere → "Inspect")
3. Click the **"Network"** tab at the top of the developer tools panel
4. In the filter box, type: `messages`
5. In Discord, click on any channel or DM so a message loads
6. A network request will appear in the list — click on it
7. Scroll down in the right panel to find **"Request Headers"**
8. Find the line that says **`authorization:`** — the long string after it is your token

It will look something like this:
```
MTExMjM0NTY3ODkwMTIzNA.GXxXxX.aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890abc
```

Copy the entire string carefully.

**Alternative method using the console:**
1. Open Discord in browser, press **F12**
2. Click the **"Console"** tab
3. Paste this exactly and press Enter:
```javascript
(webpackChunkdiscord_app.push([[''],{},e=>{m=[];for(let c in e.c)m.push(e.c[c])}]),m).find(m=>m?.exports?.default?.getToken!==void 0).exports.default.getToken()
```
4. The token will be printed in the console — copy it

---

### Step 3: Find the Channel ID(s) You Want to Monitor

A **Channel ID** is a unique number that identifies a specific Discord channel or direct message conversation.

**How to get a Channel ID:**
1. In Discord (app or browser), go to **Settings → Advanced**
2. Enable **Developer Mode**
3. Right-click on any channel, server, or DM conversation
4. Click **"Copy Channel ID"** (or "Copy ID")
5. You now have the channel ID — it will be a long number like `1234567890123456789`

For a **DM conversation**, right-click the person's name in your DM list → Copy ID.

---

## How to Use

### Option A: One-Time Evidence Export

Use this to capture a complete snapshot of channels right now.

1. Open `scripts\collect_evidence.bat` by double-clicking it
2. The script will ask you:
   - Your Discord token
   - How many channels/DMs you want to export
   - The Channel ID for each one
   - A label/name for each channel
   - Where to save the evidence
3. It will export everything to HTML files you can open in any browser
4. Run `sha256_verify.bat` afterwards to generate checksums

### Option B: Continuous Monitoring

Use this if you want to capture ongoing activity over hours or days (recommended when you suspect evidence may be deleted).

1. Open `scripts\monitor.bat` by double-clicking it
2. The script will ask you for your token and up to 3 channel IDs to monitor
3. It runs in a loop — every 5 minutes it checks for new messages
4. Leave it running in the background
5. Press **Ctrl+C** to stop at any time

### Option C: Download Media Files

Discord CDN video/image links expire after a short time. Use this script to download them permanently.

1. Make sure you have run `collect_evidence.bat` first (you need the JSON files)
2. Open `scripts\refresh_and_download.ps1` in PowerShell
3. Or run it automatically — `monitor.bat` calls it after every capture cycle

### Generate Checksums for Court

Run `scripts\sha256_verify.bat` after collecting evidence. It will:
- Calculate a SHA256 hash for every file in your evidence folder
- Save a `CHECKSUMS.txt` file
- This proves the files have not been altered — required for chain of custody in court

---

## What to Give the Police

When you contact law enforcement, provide:

1. **The evidence folder** containing:
   - All `.json` files (raw data)
   - All `.html` files (human-readable view)
   - All downloaded media files
   - `CHECKSUMS.txt` (integrity proof)
   - `export_log.txt` (shows when evidence was collected)

2. **A written statement** explaining:
   - When you discovered the situation
   - What the child told you
   - When you started collecting evidence
   - That you are the parent/guardian

3. **Do not delete anything** — even things that seem unimportant

---

## Privacy and Ethics

- This tool is designed **solely for parents/guardians** acting to protect a minor child
- Do not use this tool to spy on people without a legitimate safeguarding reason
- Evidence collected should be shared **only with law enforcement**
- Delete the Discord token from your scripts after use

---

## Reporting

- **European Union:** [Europol cybercrime reporting](https://www.europol.europa.eu/report-a-crime/report-cybercrime-online)
- **International:** [NCMEC CyberTipline](https://www.missingkids.org/gethelpnow/cybertipline) (USA-based but internationally recognized)
- **Internet Watch Foundation:** [iwf.org.uk](https://www.iwf.org.uk) (for CSAM reporting)

---

## Credits

- **DiscordChatExporter** by [Tyrrrz](https://github.com/Tyrrrz/DiscordChatExporter) — MIT License — the core export engine this toolkit wraps
- This wrapper toolkit is released under MIT License — use it freely, share it widely

---

## License

MIT License — see `LICENSE` file.

You are free to use, modify, and distribute this toolkit. If you improve it, please consider submitting a pull request so other parents benefit too.
