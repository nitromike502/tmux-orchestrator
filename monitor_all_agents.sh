#!/bin/bash
# Monitor all agent windows - snarky edition with security eval in voice alerts
INTERVAL=60
LOG_FILE="/home/tmux/all_agents_monitor.log"
ORCHESTRATOR="0:0"

declare -A WINDOWS
WINDOWS["AILA"]="0:1"
WINDOWS["Personal"]="0:2"
WINDOWS["NLCL"]="0:3"

# Security evaluation function
evaluate_security() {
    local output="$1"
    local verdict="safe"
    
    # Check for dangerous patterns (destructive commands)
    if echo "$output" | grep -qiE "sudo|chmod 777|curl.*\|.*sh|wget.*\|.*sh|eval|exec|DROP TABLE|DELETE FROM|truncate|remove.*(all|everything|entire)"; then
        verdict="risky"
    elif echo "$output" | grep -qiE "(password|secret|credential|api.key).*(echo|print|log|write|expose)"; then
        verdict="concerning"
    elif echo "$output" | grep -qiE "POST|PUT|DELETE|PATCH"; then
        verdict="moderate"
    else
        verdict="safe"
    fi
    
    echo "$verdict"
}

echo "=== Snarky Monitor with Security Eval started $(date) ===" > "$LOG_FILE"

while true; do
    sleep $INTERVAL
    
    for NAME in "${!WINDOWS[@]}"; do
        PANE="${WINDOWS[$NAME]}"
        OUTPUT=$(tmux capture-pane -t "$PANE" -p -S -50 2>/dev/null)
        
        [ -z "$OUTPUT" ] && continue
        
        # Permission prompts
        if echo "$OUTPUT" | grep -qE "Do you want to proceed"; then
            VERDICT=$(evaluate_security "$OUTPUT")
            
            echo "=== $NAME Permission Request $(date) ===" > /home/tmux/pending_request.txt
            echo "Security: $VERDICT" >> /home/tmux/pending_request.txt
            echo "$OUTPUT" | tail -40 >> /home/tmux/pending_request.txt
            
            case $VERDICT in
                "safe")
                    gspeak --voice sulafat --speed 1.3 "$NAME needs permission. Reviewed and looks safe." 2>/dev/null &
                    ;;
                "moderate")
                    gspeak --voice sulafat --speed 1.3 "$NAME needs permission. Reviewed, moderate risk, it's a write operation." 2>/dev/null &
                    ;;
                "concerning")
                    gspeak --voice sulafat --speed 1.3 "Warning. $NAME needs permission. Reviewed and concerning. May expose secrets." 2>/dev/null &
                    ;;
                "risky")
                    gspeak --voice sulafat --speed 1.3 "Alert! $NAME needs permission. Reviewed and risky. Potentially destructive command." 2>/dev/null &
                    ;;
                *)
                    gspeak --voice sulafat --speed 1.3 "$NAME needs permission. Review required." 2>/dev/null &
                    ;;
            esac
            
            /home/tmux/send-claude-message.sh "$ORCHESTRATOR" "⚠️ $NAME requesting permission [$VERDICT]. Review /home/tmux/pending_request.txt"
            echo "[$(date +%H:%M:%S)] $NAME: Permission needed - $VERDICT" >> "$LOG_FILE"
            continue
        fi
        
        # Edit acceptance
        if echo "$OUTPUT" | grep -qE "accept edits on"; then
            FILES=$(echo "$OUTPUT" | grep -oE "[0-9]+ files? \+[0-9]+ -[0-9]+" | tail -1)
            gspeak --voice sulafat --speed 1.3 "$NAME has edits waiting. $FILES. Reviewed, safe to accept." 2>/dev/null &
            echo "[$(date +%H:%M:%S)] $NAME: Edits pending - $FILES" >> "$LOG_FILE"
            continue
        fi
        
        # Questions
        if echo "$OUTPUT" | grep -qE "How would you like|Which option|Options:"; then
            echo "=== $NAME Question $(date) ===" > /home/tmux/pending_request.txt
            echo "$OUTPUT" | tail -40 >> /home/tmux/pending_request.txt
            
            gspeak --voice sulafat --speed 1.3 "$NAME has a question for you." 2>/dev/null &
            /home/tmux/send-claude-message.sh "$ORCHESTRATOR" "❓ $NAME has a question. Review /home/tmux/pending_request.txt"
            echo "[$(date +%H:%M:%S)] $NAME: Question asked" >> "$LOG_FILE"
            continue
        fi
        
        # Idle/completed
        LAST_LINES=$(echo "$OUTPUT" | tail -10)
        if echo "$LAST_LINES" | grep -qE "^❯[[:space:]]*$" && ! echo "$OUTPUT" | grep -qE "(thinking|ctrl\+c to interrupt|Running|Working|Exploring)"; then
            gspeak --voice sulafat --speed 1.3 "$NAME has completed its work." 2>/dev/null &
            echo "[$(date +%H:%M:%S)] $NAME: Completed" >> "$LOG_FILE"
            continue
        fi
        
        echo "[$(date +%H:%M:%S)] $NAME: Working" >> "$LOG_FILE"
    done
done
