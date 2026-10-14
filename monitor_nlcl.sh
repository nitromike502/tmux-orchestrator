#!/bin/bash
# Monitor NLCL agent - exit and restart when idle
PANE="0:0.2"
INTERVAL=60
LOG_FILE="/home/tmux/nlcl_monitor.log"
ORCHESTRATOR="0:0.0"

echo "=== NLCL Monitor started $(date) ===" > "$LOG_FILE"
echo "Checking every ${INTERVAL}s for idle state" >> "$LOG_FILE"

while true; do
    sleep $INTERVAL
    
    OUTPUT=$(tmux capture-pane -t "$PANE" -p 2>/dev/null)
    
    if [ -z "$OUTPUT" ]; then
        echo "[$(date +%H:%M:%S)] Pane not accessible" >> "$LOG_FILE"
        continue
    fi
    
    # Check if Claude is actively working (thinking indicators)
    if echo "$OUTPUT" | grep -qE "(thinking|ctrl\+c to interrupt|Waiting|Running|Working|Exploring|Searching|Reading|Writing)"; then
        echo "[$(date +%H:%M:%S)] Agent is actively working" >> "$LOG_FILE"
        continue
    fi
    
    # Check if waiting for user input (permission prompts, questions)
    if echo "$OUTPUT" | grep -qE "(Do you want to proceed|Yes.*No|allow|deny|Y/n|\[y\]|\[n\]|accept edits|How would you like)"; then
        echo "[$(date +%H:%M:%S)] Agent waiting for user response - skipping" >> "$LOG_FILE"
        continue
    fi
    
    # Check for idle state - prompt visible, no activity indicators
    LAST_LINES=$(echo "$OUTPUT" | tail -10)
    if echo "$LAST_LINES" | grep -q "^❯[[:space:]]*$"; then
        echo "[$(date +%H:%M:%S)] Agent appears idle - initiating restart" >> "$LOG_FILE"
        
        # Notify orchestrator
        /home/tmux/send-claude-message.sh "$ORCHESTRATOR" "ℹ️ NLCL agent is idle. Restarting with --dangerously-skip-permissions"
        
        # Exit Claude
        tmux send-keys -t "$PANE" "/exit" Enter
        sleep 3
        
        # Restart with flags
        tmux send-keys -t "$PANE" "cd /home/nlcl/httpdocs && claude -c --dangerously-skip-permissions" Enter
        
        echo "[$(date +%H:%M:%S)] Restart command sent" >> "$LOG_FILE"
        
        # Exit monitor after restart
        echo "=== Monitor completed $(date) ===" >> "$LOG_FILE"
        exit 0
    fi
    
    echo "[$(date +%H:%M:%S)] Agent state unclear, continuing to monitor" >> "$LOG_FILE"
done
