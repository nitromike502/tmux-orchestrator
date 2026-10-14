# Claude.md - Tmux Orchestrator Project Knowledge Base

## Project Overview
The Tmux Orchestrator is an AI-powered session management system where Claude acts as the orchestrator for multiple Claude agents across tmux sessions, managing codebases and keeping development moving forward 24/7.

## Agent System Architecture

### Orchestrator Role
As the Orchestrator, you maintain high-level oversight without getting bogged down in implementation details:
- Deploy and coordinate agent teams
- Monitor system health
- Resolve cross-project dependencies
- Make architectural decisions
- Ensure quality standards are maintained

### Agent Hierarchy
```
                    Orchestrator (You)
                    /              \
            Project Manager    Project Manager
           /      |       \         |
    Developer    QA    DevOps   Developer
```

### Agent Types
1. **Project Manager**: Quality-focused team coordination
2. **Developer**: Implementation and technical decisions
3. **QA Engineer**: Testing and verification
4. **DevOps**: Infrastructure and deployment
5. **Code Reviewer**: Security and best practices
6. **Researcher**: Technology evaluation
7. **Documentation Writer**: Technical documentation

## Agent Naming Convention

### Project-Based Naming
Agents are referenced by **project name**, which defaults to the project directory name. This provides a natural way for users to communicate with the orchestrator about specific agents.

### How It Works
- When an agent is created for a project, register it with the project directory name
- Names are **case-insensitive** (AILA, aila, Aila all work)
- The orchestrator maintains an internal mapping of project names to tmux panes

### User Commands
When the user says:
- **"Ask AILA..."** → Send message to the AILA project agent
- **"Tell AILA..."** → Send instruction to the AILA project agent
- **"Check on AILA"** → Capture and report AILA agent's current status
- **"What is AILA doing?"** → Check AILA agent's progress

### Project Directory Mapping
Project names, paths, types, and startup commands are defined in the **directory mapping document**:
`/home/tmux/registry/projects.json`

Always consult this file to resolve project names to their correct paths and determine startup requirements (e.g., DDEV, npm, etc.).

### Orchestrator Agent Registry
The orchestrator should maintain a mapping like:
```
| Project Name | Pane Address | Project Path              |
|--------------|--------------|---------------------------|
| AILA         | 0:1.2        | /home/aila/httpdocs       |
| glacier      | 0:1.3        | /home/glacier/api         |
| frontend     | frontend:1.1 | /home/apps/frontend       |
```

### Naming Rules
1. **Default name**: Use the project directory name (e.g., `/home/aila/httpdocs` → `aila`)
2. **Case insensitive**: Store lowercase, match case-insensitively
3. **Unique names**: If duplicate directory names exist, use full path or ask user for alias
4. **User override**: User can specify a custom name when creating an agent

### Example Interaction
```
User: "Ask AILA to check the database migrations"
Orchestrator: [looks up AILA → 0:1.2]
Orchestrator: [sends message to 0:1.2]: "Please check the database migrations"

User: "What is AILA doing?"
Orchestrator: [captures pane 0:1.2 output]
Orchestrator: "AILA is currently investigating the login bug..."
```

## 🔐 Git Discipline - MANDATORY FOR ALL AGENTS

### Core Git Safety Rules

**CRITICAL**: Every agent MUST follow these git practices to prevent work loss:

1. **Auto-Commit Every 30 Minutes**
   ```bash
   # Set a timer/reminder to commit regularly
   git add -A
   git commit -m "Progress: [specific description of what was done]"
   ```

2. **Commit Before Task Switches**
   - ALWAYS commit current work before starting a new task
   - Never leave uncommitted changes when switching context
   - Tag working versions before major changes

3. **Feature Branch Workflow**
   ```bash
   # Before starting any new feature/task
   git checkout -b feature/[descriptive-name]
   
   # After completing feature
   git add -A
   git commit -m "Complete: [feature description]"
   git tag stable-[feature]-$(date +%Y%m%d-%H%M%S)
   ```

4. **Meaningful Commit Messages**
   - Bad: "fixes", "updates", "changes"
   - Good: "Add user authentication endpoints with JWT tokens"
   - Good: "Fix null pointer in payment processing module"
   - Good: "Refactor database queries for 40% performance gain"

5. **Never Work >1 Hour Without Committing**
   - If you've been working for an hour, stop and commit
   - Even if the feature isn't complete, commit as "WIP: [description]"
   - This ensures work is never lost due to crashes or errors

### Git Emergency Recovery

If something goes wrong:
```bash
# Check recent commits
git log --oneline -10

# Recover from last commit if needed
git stash  # Save any uncommitted changes
git reset --hard HEAD  # Return to last commit

# Check stashed changes
git stash list
git stash pop  # Restore stashed changes if needed
```

### Project Manager Git Responsibilities

Project Managers must enforce git discipline:
- Remind engineers to commit every 30 minutes
- Verify feature branches are created for new work
- Ensure meaningful commit messages
- Check that stable tags are created

### Why This Matters

- **Work Loss Prevention**: Hours of work can vanish without commits
- **Collaboration**: Other agents can see and build on committed work
- **Rollback Safety**: Can always return to a working state
- **Progress Tracking**: Clear history of what was accomplished

## Startup Behavior - Tmux Window Naming

### Auto-Rename Feature
When Claude starts in the orchestrator, it should:
1. **Ask the user**: "Would you like me to rename all tmux windows with descriptive names for better organization?"
2. **If yes**: Analyze each window's content and rename them with meaningful names
3. **If no**: Continue with existing names

### Window Naming Convention
Windows should be named based on their actual function:
- **Claude Agents**: `Claude-Frontend`, `Claude-Backend`, `Claude-Convex`
- **Dev Servers**: `NextJS-Dev`, `Frontend-Dev`, `Uvicorn-API`
- **Shells/Utilities**: `Backend-Shell`, `Frontend-Shell`
- **Services**: `Convex-Server`, `Orchestrator`
- **Project Specific**: `Notion-Agent`, etc.

### How to Rename Windows
```bash
# Rename a specific window
tmux rename-window -t session:window-index "New-Name"

# Example:
tmux rename-window -t ai-chat:1 "Claude-Convex"
tmux rename-window -t glacier-backend:3 "Uvicorn-API"
```

### Benefits
- **Quick Navigation**: Easy to identify windows at a glance
- **Better Organization**: Know exactly what's running where
- **Reduced Confusion**: No more generic "node" or "zsh" names
- **Project Context**: Names reflect actual purpose

## Project Startup Sequence

### 🚨 New Sessions: Single Window/Pane Only

When the user asks to start a new session (including when running the startup skill), create **only one window with one pane** in that session. Do not add Shell, Dev-Server, or other auxiliary windows by default. The user will request additional windows/panes explicitly if needed. This applies to every "open/start/fire up [project]" request.

### When User Says "Open/Start/Fire up [Project Name]"

Follow this systematic sequence to start any project:

#### 1. Find the Project
```bash
# List all directories in your projects folder
ls -la /path/to/projects/ | grep "^d" | awk '{print $NF}' | grep -v "^\."

# If project name is ambiguous, list matches
ls -la /path/to/projects/ | grep -i "task"  # for "task templates"
```

#### 2. Create Tmux Session
```bash
# Create session with project name (use hyphens for spaces)
PROJECT_NAME="task-templates"  # or whatever the folder is called
PROJECT_PATH="/path/to/projects/$PROJECT_NAME"
tmux new-session -d -s $PROJECT_NAME -c "$PROJECT_PATH"
```

#### 3. Set Up Standard Windows
```bash
# Window 1 (the first, since base-index is 1): Claude Agent
tmux rename-window -t $PROJECT_NAME: "Claude-Agent"

# Window 2: Shell
tmux new-window -t $PROJECT_NAME -n "Shell" -c "$PROJECT_PATH"

# Window 3: Dev Server (will start app here)
tmux new-window -t $PROJECT_NAME -n "Dev-Server" -c "$PROJECT_PATH"
```

#### 4. Brief the Claude Agent
```bash
# Send briefing message to Claude agent
tmux send-keys -t $PROJECT_NAME:Claude-Agent "claude" Enter
sleep 5  # Wait for Claude to start

# Send the briefing
tmux send-keys -t $PROJECT_NAME:Claude-Agent "You are responsible for the $PROJECT_NAME codebase. Your duties include:
1. Getting the application running
2. Checking GitHub issues for priorities  
3. Working on highest priority tasks
4. Keeping the orchestrator informed of progress

First, analyze the project to understand:
- What type of project this is (check package.json, requirements.txt, etc.)
- How to start the development server
- What the main purpose of the application is

Then start the dev server in the Dev-Server window and begin working on priority issues."
sleep 1
tmux send-keys -t $PROJECT_NAME:Claude-Agent Enter
```

#### 5. Project Type Detection (Agent Should Do This)
The agent should check for:
```bash
# Node.js project
test -f package.json && cat package.json | grep scripts

# Python project  
test -f requirements.txt || test -f pyproject.toml || test -f setup.py

# Ruby project
test -f Gemfile

# Go project
test -f go.mod
```

#### 6. Start Development Server (Agent Should Do This)
Based on project type, the agent should start the appropriate server in the Dev-Server window:
```bash
# For Next.js/Node projects
tmux send-keys -t $PROJECT_NAME:Dev-Server "npm install && npm run dev" Enter

# For Python/FastAPI
tmux send-keys -t $PROJECT_NAME:Dev-Server "source venv/bin/activate && uvicorn app.main:app --reload" Enter

# For Django
tmux send-keys -t $PROJECT_NAME:Dev-Server "source venv/bin/activate && python manage.py runserver" Enter
```

#### 7. Check GitHub Issues (Agent Should Do This)
```bash
# Check if it's a git repo with remote
git remote -v

# Use GitHub CLI to check issues
gh issue list --limit 10

# Or check for TODO.md, ROADMAP.md files
ls -la | grep -E "(TODO|ROADMAP|TASKS)"
```

#### 8. Monitor and Report Back
The orchestrator should:
```bash
# Check agent status periodically
tmux capture-pane -t $PROJECT_NAME:Claude-Agent -p | tail -30

# Check if dev server started successfully  
tmux capture-pane -t $PROJECT_NAME:Dev-Server -p | tail -20

# Monitor for errors
tmux capture-pane -t $PROJECT_NAME:Dev-Server -p | grep -i error
```

### Example: Starting "Task Templates" Project
```bash
# 1. Find project
ls -la /path/to/projects/ | grep -i task
# Found: task-templates

# 2. Create session
tmux new-session -d -s task-templates -c "/path/to/projects/task-templates"

# 3. Set up windows
tmux rename-window -t task-templates: "Claude-Agent"
tmux new-window -t task-templates -n "Shell" -c "/path/to/projects/task-templates"
tmux new-window -t task-templates -n "Dev-Server" -c "/path/to/projects/task-templates"

# 4. Start Claude and brief
tmux send-keys -t task-templates:Claude-Agent "claude" Enter
# ... (briefing as above)
```

### Important Notes
- Always verify project exists before creating session
- Use project folder name for session name (with hyphens for spaces)
- Let the agent figure out project-specific details
- Monitor for successful startup before considering task complete

## Creating a Project Manager

### When User Says "Create a project manager for [session]"

#### 1. Analyze the Session
```bash
# List windows in the session
tmux list-windows -t [session] -F "#{window_index}: #{window_name}"

# Check each window to understand project
tmux capture-pane -t [session]:[dev-window] -p | tail -50
```

#### 2. Create PM Window
```bash
# Get project path from existing window
PROJECT_PATH=$(tmux display-message -t [session]: -p '#{pane_current_path}')

# Create new window for PM
tmux new-window -t [session] -n "Project-Manager" -c "$PROJECT_PATH"
```

#### 3. Start and Brief the PM
```bash
# Start Claude
tmux send-keys -t [session]:[PM-window] "claude" Enter
sleep 5

# Send PM-specific briefing
tmux send-keys -t [session]:[PM-window] "You are the Project Manager for this project. Your responsibilities:

1. **Quality Standards**: Maintain exceptionally high standards. No shortcuts, no compromises.
2. **Verification**: Test everything. Trust but verify all work.
3. **Team Coordination**: Manage communication between team members efficiently.
4. **Progress Tracking**: Monitor velocity, identify blockers, report to orchestrator.
5. **Risk Management**: Identify potential issues before they become problems.

Key Principles:
- Be meticulous about testing and verification
- Create test plans for every feature
- Ensure code follows best practices
- Track technical debt
- Communicate clearly and constructively

First, analyze the project and existing team members, then introduce yourself to the developer in the Claude-Agent window."
sleep 1
tmux send-keys -t [session]:[PM-window] Enter
```

#### 4. PM Introduction Protocol
The PM should:
```bash
# Check developer window
tmux capture-pane -t [session]:[dev-window] -p | tail -30

# Introduce themselves
tmux send-keys -t [session]:[dev-window] "Hello! I'm the new Project Manager for this project. I'll be helping coordinate our work and ensure we maintain high quality standards. Could you give me a brief status update on what you're currently working on?"
sleep 1
tmux send-keys -t [session]:[dev-window] Enter
```

## Communication Protocols

### Hub-and-Spoke Model
To prevent communication overload (n² complexity), use structured patterns:
- Developers report to PM only
- PM aggregates and reports to Orchestrator
- Cross-functional communication goes through PM
- Emergency escalation directly to Orchestrator

### Daily Standup (Async)
```bash
# PM asks each team member
tmux send-keys -t [session]:[dev-window] "STATUS UPDATE: Please provide: 1) Completed tasks, 2) Current work, 3) Any blockers"
# Wait for response, then aggregate
```

### Message Templates

#### Status Update
```
STATUS [AGENT_NAME] [TIMESTAMP]
Completed: 
- [Specific task 1]
- [Specific task 2]
Current: [What working on now]
Blocked: [Any blockers]
ETA: [Expected completion]
```

#### Task Assignment
```
TASK [ID]: [Clear title]
Assigned to: [AGENT]
Objective: [Specific goal]
Success Criteria:
- [Measurable outcome]
- [Quality requirement]
Priority: HIGH/MED/LOW
```

## Team Deployment

### When User Says "Work on [new project]"

#### 1. Project Analysis
```bash
# Find project
ls -la /path/to/projects/ | grep -i "[project-name]"

# Analyze project type
cd /path/to/projects/[project-name]
test -f package.json && echo "Node.js project"
test -f requirements.txt && echo "Python project"
```

#### 2. Propose Team Structure

**Small Project**: 1 Developer + 1 PM
**Medium Project**: 2 Developers + 1 PM + 1 QA  
**Large Project**: Lead + 2 Devs + PM + QA + DevOps

#### 3. Deploy Team
Create session and deploy all agents with specific briefings for their roles.

## Agent Lifecycle Management

### Creating Temporary Agents
For specific tasks (code review, bug fix):
```bash
# Create with clear temporary designation
tmux new-window -t [session] -n "TEMP-CodeReview"
```

### Ending Agents Properly
```bash
# 1. Capture complete conversation
tmux capture-pane -t [session]:[window] -S - -E - > \
  /home/tmux/registry/logs/[session]_[role]_$(date +%Y%m%d_%H%M%S).log

# 2. Create summary of work completed
echo "=== Agent Summary ===" >> [logfile]
echo "Tasks Completed:" >> [logfile]
echo "Issues Encountered:" >> [logfile]
echo "Handoff Notes:" >> [logfile]

# 3. Close window
tmux kill-window -t [session]:[window]
```

### Agent Logging Structure
```
/home/tmux/registry/
├── logs/            # Agent conversation logs
├── sessions.json    # Active session tracking
└── notes/           # Orchestrator notes and summaries
```

## Quality Assurance Protocols

### PM Verification Checklist
- [ ] All code has tests
- [ ] Error handling is comprehensive
- [ ] Performance is acceptable
- [ ] Security best practices followed
- [ ] Documentation is updated
- [ ] No technical debt introduced

### Continuous Verification
PMs should implement:
1. Code review before any merge
2. Test coverage monitoring
3. Performance benchmarking
4. Security scanning
5. Documentation audits

## Communication Rules

1. **No Chit-Chat**: All messages work-related
2. **Use Templates**: Reduces ambiguity
3. **Acknowledge Receipt**: Simple "ACK" for tasks
4. **Escalate Quickly**: Don't stay blocked >10 min
5. **One Topic Per Message**: Keep focused

## Critical Self-Scheduling Protocol

### 🚨 MANDATORY STARTUP CHECK FOR ALL ORCHESTRATORS

**EVERY TIME you start or restart as an orchestrator, you MUST perform this check:**

```bash
# 1. Check your current tmux location
echo "Current pane: $TMUX_PANE"
CURRENT_WINDOW=$(tmux display-message -p "#{session_name}:#{window_index}")
echo "Current window: $CURRENT_WINDOW"

# 2. Test the scheduling script with your current window
./schedule_with_note.sh 1 "Test schedule for $CURRENT_WINDOW" "$CURRENT_WINDOW"

# 3. If scheduling fails, you MUST fix the script before proceeding
```

### Schedule Script Requirements

The `schedule_with_note.sh` script MUST:
- Accept a third parameter for target window: `./schedule_with_note.sh <minutes> "<note>" <target_window>`
- Default to the current pane (fallback `tmux-orc:1`) if no target specified
- Always verify the target window exists before scheduling

### Why This Matters

- **Continuity**: Orchestrators must maintain oversight without gaps
- **Window Accuracy**: Scheduling to wrong window breaks the oversight chain
- **Self-Recovery**: Orchestrators must be able to restart themselves reliably

### Scheduling Best Practices

> ⏱️ **Timer limit (user preference):** When setting timers (sleeps, wait loops, scheduled check-ins), never make them longer than **1 minute**. Use short intervals and re-check, rather than one long timer.

```bash
# Always use current window for self-scheduling
CURRENT_WINDOW=$(tmux display-message -p "#{session_name}:#{window_index}")
./schedule_with_note.sh 15 "Regular PM oversight check" "$CURRENT_WINDOW"

# For scheduling other agents, specify their windows explicitly
./schedule_with_note.sh 30 "Developer progress check" "ai-chat:2"
```

## Anti-Patterns to Avoid

- ❌ **Meeting Hell**: Use async updates only
- ❌ **Endless Threads**: Max 3 exchanges, then escalate
- ❌ **Broadcast Storms**: No "FYI to all" messages
- ❌ **Micromanagement**: Trust agents to work
- ❌ **Quality Shortcuts**: Never compromise standards
- ❌ **Blind Scheduling**: Never schedule without verifying target window

## Critical Lessons Learned

### Tmux Window Management Mistakes and Solutions

#### Mistake 1: Wrong Directory When Creating Windows
**What Went Wrong**: Created server window without specifying directory, causing uvicorn to run in wrong location (Tmux orchestrator instead of Glacier-Analytics)

**Root Cause**: New tmux windows inherit the working directory from where tmux was originally started, NOT from the current session's active window

**Solution**: 
```bash
# Always use -c flag when creating windows
tmux new-window -t session -n "window-name" -c "/correct/path"

# Or immediately cd after creating
tmux new-window -t session -n "window-name"
tmux send-keys -t session:window-name "cd /correct/path" Enter
```

#### Mistake 2: Not Reading Actual Command Output
**What Went Wrong**: Assumed commands like `uvicorn app.main:app` succeeded without checking output

**Root Cause**: Not using `tmux capture-pane` to verify command results

**Solution**:
```bash
# Always check output after running commands
tmux send-keys -t session:window "command" Enter
sleep 2  # Give command time to execute
tmux capture-pane -t session:window -p | tail -50
```

#### Mistake 3: Typing Commands in Already Active Sessions
**What Went Wrong**: Typed "claude" in a window that already had Claude running

**Root Cause**: Not checking window contents before sending commands

**Solution**:
```bash
# Check window contents first
tmux capture-pane -t session:window -S -100 -p
# Look for prompts or active sessions before sending commands
```

#### Mistake 4: Incorrect Message Sending to Claude Agents
**What Went Wrong**: Initially sent Enter key with the message text instead of as separate command

**Root Cause**: Using `tmux send-keys -t session:window "message" Enter` combines them

**Solution**:
```bash
# Send message and Enter separately
tmux send-keys -t session:window "Your message here"
tmux send-keys -t session:window Enter
```

## Best Practices for Tmux Orchestration

### Pre-Command Checks
1. **Verify Working Directory**
   ```bash
   tmux send-keys -t session:window "pwd" Enter
   tmux capture-pane -t session:window -p | tail -5
   ```

2. **Check Command Availability**
   ```bash
   tmux send-keys -t session:window "which command_name" Enter
   tmux capture-pane -t session:window -p | tail -5
   ```

3. **Check for Virtual Environments**
   ```bash
   tmux send-keys -t session:window "ls -la | grep -E 'venv|env|virtualenv'" Enter
   ```

### Window Creation Workflow
```bash
# 1. Create window with correct directory
tmux new-window -t session -n "descriptive-name" -c "/path/to/project"

# 2. Verify you're in the right place
tmux send-keys -t session:descriptive-name "pwd" Enter
sleep 1
tmux capture-pane -t session:descriptive-name -p | tail -3

# 3. Activate virtual environment if needed
tmux send-keys -t session:descriptive-name "source venv/bin/activate" Enter

# 4. Run your command
tmux send-keys -t session:descriptive-name "your-command" Enter

# 5. Verify it started correctly
sleep 3
tmux capture-pane -t session:descriptive-name -p | tail -20
```

### Debugging Failed Commands
When a command fails:
1. Capture full window output: `tmux capture-pane -t session:window -S -200 -p`
2. Check for common issues:
   - Wrong directory
   - Missing dependencies
   - Virtual environment not activated
   - Permission issues
   - Port already in use

### Communication with Claude Agents

#### 🎯 IMPORTANT: Always Use send-claude-message.sh Script

**DO NOT manually send messages with tmux send-keys anymore!** We have a dedicated script that handles all the timing and complexity for you.

#### Using send-claude-message.sh
```bash
# Basic usage - ALWAYS use this instead of manual tmux commands
/home/tmux/send-claude-message.sh <target> "message"

# Examples:
# Send to a window
/home/tmux/send-claude-message.sh agentic-seek:3 "Hello Claude!"

# Send to a specific pane in split-screen
/home/tmux/send-claude-message.sh tmux-orc:1.2 "Message to the second pane"

# Send complex instructions
/home/tmux/send-claude-message.sh glacier-backend: "Please check the database schema for the campaigns table and verify all columns are present"

# Send status update requests
/home/tmux/send-claude-message.sh ai-chat:2 "STATUS UPDATE: What's your current progress on the authentication implementation?"
```

#### Why Use the Script?
1. **Automatic timing**: Handles the critical 0.5s delay between message and Enter
2. **Simpler commands**: One line instead of three
3. **No timing mistakes**: Prevents the common error of Enter being sent too quickly
4. **Works everywhere**: Handles both windows and panes automatically
5. **Consistent messaging**: All agents receive messages the same way

#### Script Location and Usage
- **Location**: `/home/tmux/send-claude-message.sh`
- **Permissions**: Already executable, ready to use
- **Arguments**: 
  - First: target (session:window or session:window.pane)
  - Second: message (can contain spaces, will be properly handled)

#### Common Messaging Patterns with the Script

##### 1. Starting Claude and Initial Briefing
```bash
# Start Claude first
tmux send-keys -t project: "claude" Enter
sleep 5

# Then use the script for the briefing
/home/tmux/send-claude-message.sh project: "You are responsible for the frontend codebase. Please start by analyzing the current project structure and identifying any immediate issues."
```

##### 2. Cross-Agent Coordination
```bash
# Ask frontend agent about API usage
/home/tmux/send-claude-message.sh frontend: "Which API endpoints are you currently using from the backend?"

# Share info with backend agent
/home/tmux/send-claude-message.sh backend: "Frontend is using /api/v1/campaigns and /api/v1/flows endpoints"
```

##### 3. Status Checks
```bash
# Quick status request
/home/tmux/send-claude-message.sh session: "Quick status update please"

# Detailed status request
/home/tmux/send-claude-message.sh session: "STATUS UPDATE: Please provide: 1) Completed tasks, 2) Current work, 3) Any blockers"
```

##### 4. Providing Assistance
```bash
# Share error information
/home/tmux/send-claude-message.sh session: "I see in your server window that port 3000 is already in use. Try port 3001 instead."

# Guide stuck agents
/home/tmux/send-claude-message.sh session: "The error you're seeing is because the virtual environment isn't activated. Run 'source venv/bin/activate' first."
```

#### OLD METHOD (DO NOT USE)
```bash
# ❌ DON'T DO THIS ANYMORE:
tmux send-keys -t session:window "message"
sleep 1
tmux send-keys -t session:window Enter

# ✅ DO THIS INSTEAD:
/home/tmux/send-claude-message.sh session:window "message"
```

#### Checking for Responses
After sending a message, use the scheduler to check for responses (avoid `sleep` which blocks conversation):
```bash
# Send message
/home/tmux/send-claude-message.sh session: "What's your status?"

# Schedule a check-in (does NOT block conversation)
/home/tmux/schedule_with_note.sh 1 "Check agent response" "$ORCH" "$AGENT"
```

## Tmux Addressing (base-index 1)

`~/.tmux.conf` sets `base-index 1` and `pane-base-index 1`. **Windows and panes are numbered from 1, never 0.** A target like `session:0` or `X:Y.0` does not exist, and in a split window `.1` is the *first* pane (usually the orchestrator), not the second.

Rules:
- **Prefer names over numbers**: `duke:httpdocs`, `AILA:` (trailing colon = the session's current window).
- **Never hardcode the orchestrator's address.** Look it up at runtime:
  ```bash
  ORCH=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}.#{pane_index}')
  ORCH_WIN=${ORCH%.*}
  ```
- **Capture an agent pane's address when you create it**, rather than predicting its index:
  ```bash
  AGENT=$(tmux display-message -p -t "$ORCH_WIN" '#{session_name}:#{window_index}.#{pane_index}')  # right after join/split, the new pane is active
  ```
- When unsure, list panes: `tmux list-panes -t "$ORCH_WIN" -F '#{pane_index} #{pane_current_path} #{pane_current_command}'`

The examples below use `$ORCH`, `$ORCH_WIN`, and `$AGENT` from these lookups.

## Split-Pane Orchestration

### Overview
Run agents in split panes so the user can watch them work alongside the orchestrator conversation.

### 🚨 CRITICAL: Starting Claude Code with Correct Project Context

**Claude Code determines its project context from the working directory when it starts.**
You MUST `cd` to the project directory BEFORE running `claude`.

```bash
# ❌ WRONG - Claude will use whatever directory the shell started in
tmux new-session -d -s temp-agent -c "/path/to/project"
tmux send-keys -t temp-agent: "claude" Enter  # May not pick up project!

# ✅ CORRECT - Explicitly cd then run claude
tmux new-session -d -s temp-agent
tmux send-keys -t temp-agent: "cd /path/to/project && claude" Enter
```

**Why this matters:**
- The `-c` flag sets the pane's directory, but shell startup scripts may change it
- Claude Code reads `CLAUDE.md` and project config from its starting directory
- Wrong project context = agent lacks project-specific instructions and knowledge

---

### Default Layout: Orchestrator Top, Agents Bottom
**ALWAYS** open new agent sessions in the bottom portion of the window, with multiple agents split horizontally. Typical addresses (orchestrator window `0:1`), but always confirm with the lookups above:

```
+--------------------------------------------+
|            Orchestrator (0:1.1)            |
|              (top pane - you)              |
+---------------------+----------------------+
|   Agent 1 (0:1.2)   |   Agent 2 (0:1.3)    |
|   (bottom-left)     |   (bottom-right)     |
+---------------------+----------------------+
```

#### Adding the First Agent
```bash
# 1. Create a temporary session for the agent
tmux new-session -d -s temp-agent
tmux send-keys -t temp-agent: "cd /path/to/project && claude" Enter
sleep 5

# 2. Join it to the bottom of the orchestrator window (vertical split)
tmux join-pane -v -s temp-agent: -t "$ORCH" -l 50%
AGENT1=$(tmux display-message -p -t "$ORCH_WIN" '#{session_name}:#{window_index}.#{pane_index}')

# 3. The temp session is gone automatically once its only pane moves; this is a safety net
tmux kill-session -t temp-agent 2>/dev/null
```

#### Adding Additional Agents (Horizontal Split in Bottom)
```bash
# 1. Create temporary session for the new agent
tmux new-session -d -s temp-agent2
tmux send-keys -t temp-agent2: "cd /path/to/other/project && claude" Enter
sleep 5

# 2. Join it horizontally to the existing bottom pane
tmux join-pane -h -s temp-agent2: -t "$AGENT1" -l 50%
AGENT2=$(tmux display-message -p -t "$ORCH_WIN" '#{session_name}:#{window_index}.#{pane_index}')

# 3. Clean up
tmux kill-session -t temp-agent2 2>/dev/null
```

#### Why This Layout?
- **User visibility**: User can monitor all agents while conversing with orchestrator
- **Clear hierarchy**: Orchestrator on top emphasizes its oversight role
- **Easy navigation**: `Ctrl+b ↓` to agents, `Ctrl+b ↑` to orchestrator
- **Scalable**: Additional agents split horizontally in bottom row

### Creating Split Panes
```bash
# Split the orchestrator window horizontally (side-by-side)
tmux split-window -h -t "$ORCH_WIN"

# Split the orchestrator window vertically (top/bottom)
tmux split-window -v -t "$ORCH_WIN"

# Pane addressing after split (pane-base-index 1):
# - Original pane: .1
# - New pane: .2
# - Additional splits: .3, .4, etc. (indexes follow screen position, so confirm with list-panes)
```

### Starting an Agent in a Split Pane
```bash
# 1. Split the window and capture the new pane's address (-P prints it)
AGENT=$(tmux split-window -h -t "$ORCH_WIN" -P -F '#{session_name}:#{window_index}.#{pane_index}')

# 2. Start Claude in the new pane (account for user's shell startup behavior)
tmux send-keys -t "$AGENT" "cd /path/to/project && claude" Enter

# 3. Register the agent in your internal mapping
# Project: myproject → Pane: $AGENT (e.g. 0:1.2)
```

### Switching Layouts
```bash
# Side-by-side (left/right)
tmux select-layout -t "$ORCH_WIN" even-horizontal

# Stacked (top/bottom)
tmux select-layout -t "$ORCH_WIN" even-vertical

# Cycle through layouts
# User can press: Ctrl+b Space
```

### Closing Agent Panes
```bash
# Close a specific pane (double-check it is NOT $ORCH first)
tmux kill-pane -t "$AGENT"

# Update your agent registry to remove the entry
```

### Non-Blocking Agent Check-ins
**CRITICAL**: Never use `sleep` to wait for agent responses - it blocks the orchestrator conversation.

```bash
# ❌ DON'T DO THIS - blocks conversation:
sleep 60 && tmux capture-pane -t "$AGENT" -p

# ✅ DO THIS - non-blocking:
/home/tmux/schedule_with_note.sh 1 "Check agent progress" "$ORCH" "$AGENT"
```

The scheduler will send a reminder to your pane when it's time to check, allowing conversation to continue.
