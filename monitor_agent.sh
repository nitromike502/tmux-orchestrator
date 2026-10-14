#!/bin/bash
# Monitor agent pane for permission requests
# Usage: ./monitor_agent.sh <pane> <interval_seconds>

PANE=${1:-"0:0.1"}
INTERVAL=${2:-30}
TARGET="0:0.0"
LOG_FILE="/home/tmux/agent_monitor.log"

echo "Monitoring $PANE every ${INTERVAL}s - logging to $LOG_FILE"
echo "=== Monitor started $(date) ===" > "$LOG_FILE"

while true; do
    sleep $INTERVAL
    
    # Capture pane output
    OUTPUT=$(tmux capture-pane -t "$PANE" -p 2>/dev/null)
    
    if [ -z "$OUTPUT" ]; then
        echo "[$(date +%H:%M:%S)] Pane $PANE not accessible" >> "$LOG_FILE"
        continue
    fi
    
    # Check for permission patterns
    if echo "$OUTPUT" | grep -qiE "(allow|deny|yes/no|Y/n|permission|approve|accept|reject|\[y\]|\[n\])"; then
        echo "[$(date +%H:%M:%S)] ⚠️ PERMISSION REQUEST DETECTED" >> "$LOG_FILE"
        echo "$OUTPUT" | tail -30 >> "$LOG_FILE"
        
        # Alert orchestrator
        /home/tmux/send-claude-message.sh "$TARGET" "⚠️ NLCL Agent has a permission request. Check pane 0:0.1"
    else
        echo "[$(date +%H:%M:%S)] Agent running normally" >> "$LOG_FILE"
    fi
done
