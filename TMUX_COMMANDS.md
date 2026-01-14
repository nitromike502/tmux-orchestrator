# Tmux Command Reference Guide

## Understanding Tmux Structure

```
Server → Sessions → Windows → Panes
```

- **Server**: Runs in background, manages everything
- **Session**: A collection of windows (like a workspace)
- **Window**: A full-screen view (like browser tabs)
- **Pane**: Split sections within a window

## The Prefix Key

Most tmux commands require a **prefix key** first: `Ctrl+b`
(Press Ctrl+b, release, then press the next key)

---

## Session Management

| Action | Command |
|--------|---------|
| Start new session | `tmux` or `tmux new -s name` |
| List sessions | `tmux ls` |
| Attach to session | `tmux attach -t name` or `tmux a -t name` |
| Detach from session | `Ctrl+b d` |
| Kill session | `tmux kill-session -t name` |
| Rename session | `Ctrl+b $` |
| Switch sessions | `Ctrl+b s` (shows session list) |

---

## Window Management

| Action | Command |
|--------|---------|
| Create new window | `Ctrl+b c` |
| Close current window | `Ctrl+b &` or type `exit` |
| Next window | `Ctrl+b n` |
| Previous window | `Ctrl+b p` |
| Go to window # | `Ctrl+b 0-9` |
| Rename window | `Ctrl+b ,` |
| List windows | `Ctrl+b w` (interactive picker) |
| Find window | `Ctrl+b f` |

---

## Pane Management (Splits)

| Action | Command |
|--------|---------|
| Split horizontally (top/bottom) | `Ctrl+b "` |
| Split vertically (left/right) | `Ctrl+b %` |
| Close current pane | `Ctrl+b x` or type `exit` |
| Move between panes | `Ctrl+b arrow-keys` |
| Cycle through panes | `Ctrl+b o` |
| Toggle pane zoom (fullscreen) | `Ctrl+b z` |
| Resize pane | `Ctrl+b Ctrl+arrow` (hold Ctrl) |
| Show pane numbers | `Ctrl+b q` |
| Jump to pane # | `Ctrl+b q` then number |
| Swap panes | `Ctrl+b {` or `Ctrl+b }` |
| Convert pane to window | `Ctrl+b !` |

---

## Mouse Mode

### Enable Mouse (Interactive)
Press `Ctrl+b :` then type:
```
set -g mouse on
```

### Disable Mouse
Press `Ctrl+b :` then type:
```
set -g mouse off
```

### Make Mouse Permanent
Add to `~/.tmux.conf`:
```bash
set -g mouse on
```
Then reload: `tmux source-file ~/.tmux.conf`

### What Mouse Mode Allows
- Click to select panes
- Click to select windows in status bar
- Drag pane borders to resize
- Scroll with mouse wheel
- Select text (hold Shift for normal terminal selection)

---

## Copy Mode (Scrolling & Copying)

| Action | Command |
|--------|---------|
| Enter copy mode | `Ctrl+b [` |
| Exit copy mode | `q` or `Esc` |
| Scroll up | `↑` or `PgUp` |
| Scroll down | `↓` or `PgDn` |
| Start selection | `Space` |
| Copy selection | `Enter` |
| Paste | `Ctrl+b ]` |
| Search up | `?` then type search |
| Search down | `/` then type search |
| Next match | `n` |
| Previous match | `N` |

---

## Command Mode

Enter command mode: `Ctrl+b :`

Useful commands to type:
```bash
# Set options
set -g mouse on                    # Enable mouse
set -g history-limit 10000         # More scrollback
set -g base-index 1                # Windows start at 1

# Window operations
rename-window "new-name"
swap-window -t 0                   # Move to position 0

# Pane operations
select-pane -t 0                   # Select pane 0
resize-pane -D 10                  # Resize down 10 lines
resize-pane -R 20                  # Resize right 20 cols
```

---

## External Commands (From Shell)

```bash
# Session management
tmux new -s mysession              # New named session
tmux ls                            # List sessions
tmux attach -t mysession           # Attach to session
tmux kill-session -t mysession     # Kill session
tmux kill-server                   # Kill everything

# Send commands to tmux
tmux send-keys -t session:window "command" Enter
tmux capture-pane -t session:window -p    # Get pane content

# Window management
tmux new-window -t session -n "name"
tmux rename-window -t session:0 "new-name"
tmux list-windows -t session

# Get info
tmux display-message -p "#{session_name}"
tmux list-panes -t session:window
```

---

## Essential ~/.tmux.conf Settings

Create/edit `~/.tmux.conf`:
```bash
# Enable mouse
set -g mouse on

# Increase scrollback buffer
set -g history-limit 50000

# Start windows and panes at 1 instead of 0
set -g base-index 1
setw -g pane-base-index 1

# Faster key repetition
set -s escape-time 0

# Reload config shortcut: Ctrl+b r
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Easier pane splitting (| and -)
bind | split-window -h
bind - split-window -v

# Better pane navigation (vim-style)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
```

After editing, reload with:
```bash
tmux source-file ~/.tmux.conf
```

---

## Quick Reference Card

```
Ctrl+b d     → Detach
Ctrl+b c     → New window
Ctrl+b n/p   → Next/prev window
Ctrl+b 0-9   → Go to window #
Ctrl+b ,     → Rename window
Ctrl+b w     → Window list
Ctrl+b "     → Split horizontal
Ctrl+b %     → Split vertical
Ctrl+b arrow → Move between panes
Ctrl+b z     → Zoom pane toggle
Ctrl+b x     → Close pane
Ctrl+b [     → Scroll mode (q to exit)
Ctrl+b :     → Command mode
```

---

## Common Workflows

### Start a New Project Session
```bash
tmux new -s myproject
# Now you're in tmux, create windows as needed
```

### Detach and Come Back Later
```bash
# Inside tmux: Ctrl+b d
# Later, to return:
tmux attach -t myproject
```

### Split Screen Workflow
```bash
Ctrl+b %     # Split vertically (side by side)
Ctrl+b "     # Split horizontally (top/bottom)
Ctrl+b z     # Zoom current pane (toggle)
```

### Copy Text from Scrollback
```bash
Ctrl+b [     # Enter copy mode
# Navigate to text with arrows
Space        # Start selection
# Move to end of selection
Enter        # Copy
Ctrl+b ]     # Paste
```
