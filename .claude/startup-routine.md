# Startup Routine

This document defines how to start project environments. The `/startup` command takes free-form natural language — project names plus anything the user wants done with them. Look each project up in `/home/tmux/registry/projects.json` and follow the procedure below.

---

## Core Principle: Terminals First, Nothing Runs by Default

`/startup` builds the **terminal environment** — sessions, windows, panes, working directories. That is all it does unless the user asks for more.

- **Do NOT start DDEV (or any service) by default.**
- **Do NOT start Claude Code by default.**
- Only start something when the user's request says to (e.g. "start aila with ddev", "fire up nlcl and launch claude", "start everything").

A project's `services` array in `projects.json` describes what that project *can* run, not what to run automatically. Treat it as a menu, not an instruction.

---

## Tmux Addressing: Windows and Panes Start at 1

`~/.tmux.conf` sets `base-index 1` and `pane-base-index 1`, so a new session's first window is `:1` and `<session>:0` **does not exist**. Target windows by **name** (`duke:httpdocs`) or with a trailing colon (`personal:` = that session's current window). Never use a numeric `:0`.

For `<orchestrator-pane>` in Phase 2, look it up rather than assuming `0:0`:

```bash
ORCH=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}.#{pane_index}')
```

After a `join-pane`, the joined pane is active, so `tmux display-message -p -t "${ORCH%.*}" '#{session_name}:#{window_index}.#{pane_index}'` gives its address (use that as `<bottom-pane>`).

---

## Project Configuration

All project metadata lives in `/home/tmux/registry/projects.json`. Each project entry provides:

| Field | Purpose |
|---|---|
| `name` / `aliases` | How the user refers to the project |
| `path` | Working directory for the project |
| `session_name` | Tmux session name to create |
| `services` | Services this project *supports* (e.g. `["ddev"]`). Available on request only — never started by default. |

---

## Interpreting the Request

The argument is natural language. Parse it for two things:

1. **Which projects** — match words against `name` and `aliases` (case-insensitive). If a name doesn't match anything, report it and skip that project.
2. **What to do beyond terminal setup** — services to start, whether to launch Claude Code, window/pane layout requests, anything else the user spelled out.

If the request names projects but says nothing about services or Claude, do Phase 1 only and stop. Report what was created and mention what's available to start (e.g. "AILA has ddev available — say the word").

If no projects are named at all, list the available projects from the registry and ask which to start.

---

## Phase 1: Build All Terminals (Always)

**This phase runs first and completes fully before anything is launched in any pane.**

`Ctrl+b s` and `Ctrl+b w` are bound to `choose-tree -O index` in `~/.tmux.conf`, which sorts sessions by creation order and windows by index. Creation order *is* display order — so create every requested session up front, in the exact order the user listed them:

```bash
tmux new-session -d -s <first>  -c <path>   # user's 1st project
tmux new-session -d -s <second> -c <path>   # user's 2nd project
tmux new-session -d -s <third>  -c <path>   # user's 3rd project
```

Same rule inside a session — create windows in the order the user listed them:

```bash
tmux new-window -t <session> -n <first-window>  -c <path>
tmux new-window -t <session> -n <second-window> -c <path>
```

Never reorder creation to get a slow service started sooner. Services don't start in this phase at all.

Then, per session:

1. **Verify it exists** rather than blindly recreating:
   ```bash
   tmux has-session -t <session_name> 2>/dev/null || tmux new-session -d -s <session_name> -c <path>
   ```
2. **Confirm the working directory** in each pane:
   ```bash
   tmux send-keys -t <session_name>:<window-name-or-empty> "cd <path> && pwd" Enter   # e.g. duke:httpdocs or personal:
   ```

When Phase 1 finishes, every requested session and window exists, in the user's order, sitting at the right directory with an idle shell. Report this state before going further.

---

## Phase 2: Launch What Was Requested (Only If Asked)

Skip this phase entirely when the user asked only for terminals.

### Watching progress in the orchestrator window

Join a project's pane into the orchestrator window only while something is actually starting in it, then send it home. Skip the join/break dance for anything that doesn't need watching.

- **First project**: vertical split into the bottom section.
  ```bash
  tmux join-pane -v -s <session_name>:<window> -t <orchestrator-pane> -l 40%
  ```
- **Additional projects**: horizontal split within the bottom section.
  ```bash
  tmux join-pane -h -s <session_name>:<window> -t <bottom-pane> -l 50%
  ```

⚠️ A session dies when its last window's pane is moved away. If a session has only one window, give it a second window (or skip the join) before moving its pane elsewhere.

### Services (on request)

Iterate only over the services the user asked for.

#### `ddev`

```bash
ddev status   # check if already running
ddev start    # if not running
```

- **Wait for "Successfully started"** before moving on.
- If it fails, try `ddev restart` once.
- **DDEV instances must be started sequentially** — never run two `ddev start` commands at the same time due to shared `ssh-auth-compose` config conflicts.

#### (Future service types go here)

Add new service handlers to this section as needed (e.g., `docker-compose`, `npm-dev`). No other file changes required.

### Claude Code (on request)

```bash
tmux send-keys -t <pane> "claude" Enter
```

**Do NOT interact with any Claude Code prompts** (effort, model, etc.) — leave those for the user. Move on immediately.

### Return the pane to its session

```bash
tmux break-pane -d -s <pane-address> -t <session_name>:
tmux move-window -s <session_name>:<new-index> -t <session_name>:<original-index>
```

`break-pane` appends the window at the end of the list, so the `move-window` is required to restore the user's requested window order. Verify the pane left the orchestrator window and the window order still matches what the user asked for.

---

## Ordering Rules

1. **Phase 1 completes before Phase 2 begins.** All terminals exist and are in place before anything runs in any of them.
2. **Sessions and windows are created in the user's stated order — no exceptions.** Creation order is what the user sees in `Ctrl+b s` / `Ctrl+b w`.
3. **DDEV projects start sequentially relative to each other** — shared `ssh-auth-compose` config conflicts.
4. **Use DDEV wait time on other projects.** A `ddev start` can take 1-3 minutes; work other projects' Phase 2 steps while it runs.
5. **Check DDEV progress between other projects' steps.** After each non-DDEV project's setup, check whether the DDEV start finished.

---

## Post-Startup

- Verify all tmux sessions are running with their own panes, in the requested order
- Report a summary: terminals created, anything started, any errors
- Orchestrator window should be back to a single pane
