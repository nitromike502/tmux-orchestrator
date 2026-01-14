#!/bin/bash
# Dynamic scheduler with note for next check
# Usage: ./schedule_with_note.sh <minutes> "<note>" [target_window] [agent_pane_to_check]
#
# Examples:
#   ./schedule_with_note.sh 1 "Check agent progress" 0:0.0 0:0.1
#   ./schedule_with_note.sh 2 "Status update"  # Uses defaults
#
# Arguments:
#   minutes          - How long to wait before sending reminder (default: 3)
#   note             - The reminder message (default: "Standard check-in")
#   target_window    - Where to send the reminder (default: current window)
#   agent_pane       - Optional: pane to capture output from for status check

MINUTES=${1:-3}
NOTE=${2:-"Standard check-in"}
TARGET=${3:-$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null || echo "0:0.0")}
AGENT_PANE=${4:-""}

# Create a note file for the next check
NOTE_FILE="/home/tmux/next_check_note.txt"
echo "=== Next Check Note ($(date)) ===" > "$NOTE_FILE"
echo "Scheduled for: $MINUTES minutes" >> "$NOTE_FILE"
echo "Target: $TARGET" >> "$NOTE_FILE"
[ -n "$AGENT_PANE" ] && echo "Agent pane to check: $AGENT_PANE" >> "$NOTE_FILE"
echo "" >> "$NOTE_FILE"
echo "$NOTE" >> "$NOTE_FILE"

echo "Scheduling check in $MINUTES minutes with note: $NOTE"
echo "Target window: $TARGET"

# Calculate the exact time when the check will run
CURRENT_TIME=$(date +"%H:%M:%S")
RUN_TIME=$(date -d "+${MINUTES} minutes" +"%H:%M:%S" 2>/dev/null || date -v +${MINUTES}M +"%H:%M:%S" 2>/dev/null)

# Build the command to send
SLEEP_SECONDS=$(echo "$MINUTES * 60" | bc)

if [ -n "$AGENT_PANE" ]; then
    # If agent pane specified, include a capture command
    REMINDER_CMD="Scheduled reminder: $NOTE -- To check agent status run: tmux capture-pane -t $AGENT_PANE -p -S -50"
else
    REMINDER_CMD="Scheduled reminder: $NOTE"
fi

# Use nohup to completely detach the sleep process
# Sends reminder, shows note file, and runs status check via tmux_utils.py
nohup bash -c "sleep $SLEEP_SECONDS && tmux send-keys -t $TARGET \"$REMINDER_CMD\" && sleep 0.5 && tmux send-keys -t $TARGET Enter && sleep 1 && tmux send-keys -t $TARGET 'cat /home/tmux/next_check_note.txt && python3 /home/tmux/tmux_utils.py' && sleep 0.5 && tmux send-keys -t $TARGET Enter" > /dev/null 2>&1 &

# Get the PID of the background process
SCHEDULE_PID=$!

echo "Scheduled successfully - process detached (PID: $SCHEDULE_PID)"
echo "SCHEDULED TO RUN AT: $RUN_TIME (in $MINUTES minutes from $CURRENT_TIME)"
