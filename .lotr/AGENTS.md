# Lord of the Skills — Agent Bootstrap

This project uses [lotr](https://github.com/Bilal140202/the-lord-of-the-skills),
a CLI for installing AI agent skills from The Lord of the Skills compilation.

## Available Commands

```bash
# Install skills for a specific task
lotr install "write unit tests"
lotr install "add authentication"
lotr install "deploy to kubernetes"

# Full project kickoff (multiple kingdoms)
lotr kickoff "building a tauri app"

# Safe defaults (if unsure what you need)
lotr starter

# Explore available skills
lotr list              # skills for your detected framework
lotr search "react"    # search by keyword
lotr kingdoms          # list all 11 kingdoms
lotr detect            # show detected framework + stack

# Dry run (see what would install)
lotr preview "write unit tests"

# Update installed skills
lotr update
```

## The 11 Kingdoms

| Kingdom | Domain |
|:---|:---|
| ⚔ Gondor | Coding & Software Engineering |
| ✦ Rivendell | Research & Knowledge |
| ⚙ Isengard | Agents & Orchestration |
| ✎ The Shire | Writing & Content |
| ⛏ Moria | DevOps & Infrastructure |
| 🐴 Rohan | Testing & Verification |
| 🌳 Fangorn | Documentation & Memory |
| ✿ Lothlórien | Data & Analysis |
| 👁 Mordor | Security & Auditing |
| 🕸 Mirkwood | Specialized & Niche |

## How It Works

1. lotr detects your framework (cursor, claude-code, cline, etc.)
2. You describe a task in natural language
3. lotr matches it to the right kingdom(s)
4. Downloads only the canonical skills you need (2-15 files, not 18,000)
5. Places them in the right location for your framework

## When to Use lotr

- **Starting a new project**: `lotr kickoff "building a ..."`
- **Mid-project task**: `lotr install "write unit tests"`
- **Unsure what you need**: `lotr starter`
- **Looking for specific skill**: `lotr search "keyword"`

Installed skills live in your framework's skills directory (e.g., `.cursor/rules/`,
`~/.claude/skills/`, `.clinerules/`). Restart your agent after installing new skills.
