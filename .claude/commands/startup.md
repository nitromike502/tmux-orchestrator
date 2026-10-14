---
description: Execute morning startup routine for project environments
argument-hint: [projects and what to do with them, in plain English]
allowedTools: ["Bash", "Read", "Write", "Glob", "Grep"]
---

# Morning Startup Routine

Start project environments by reading and following the procedure in `/home/tmux/.claude/startup-routine.md`.

**Terminals first, nothing runs by default.** This command builds tmux sessions, windows, and panes. DDEV, Claude Code, and any other service start *only* when the request asks for them.

## Instructions

1. **Read the routine document** at `/home/tmux/.claude/startup-routine.md`
2. **Read the project registry** at `/home/tmux/registry/projects.json`
3. **Interpret the request** — pull out which projects are wanted and what (if anything) should be launched in them
4. **Phase 1: build all terminals** for every resolved project, in the order the user listed them, and finish that phase completely before running anything
5. **Phase 2: launch only what was asked for** — skip entirely if the request was terminals only
6. **Report progress** using status emojis as each project completes

## Arguments

$ARGUMENTS

Free-form natural language. Name the projects (matched case-insensitively against `name` and `aliases` in `projects.json`) and, optionally, say what to do with them.

Examples:
- `/startup aila nlcl personal` — build terminals for all three, start nothing
- `/startup marketplace` — build the Marketplace terminals only
- `/startup aila with ddev, and launch claude in nlcl` — terminals for both, then ddev on AILA and Claude Code in NLCL
- `/startup start everything for duke` — terminals plus all of Duke's supported services and Claude Code

If no projects are named, list the available projects from the registry and ask which ones to start.
