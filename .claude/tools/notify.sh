#!/usr/bin/env bash

# Claude Code notification hook script
# Reads JSON from stdin and sends desktop notifications
#
# Expected JSON input format:
# {
#   "session_id": "abc123",
#   "transcript_path": "/path/to/transcript.jsonl",
#   "cwd": "/path/to/project",
#   "hook_event_name": "Notification",
#   "message": "Task completed successfully"
# }

set -euo pipefail

# Check for debug flag
DEBUG=false
LOG_FILE="/tmp/claude-code-notify-$(date +%Y%m%d-%H%M%S).log"
if [[ "${1:-}" == "--debug" ]]; then
    DEBUG=true
    shift
fi

# Debug logging function
debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        local msg="[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*"
        echo "$msg" >&2
        echo "$msg" >> "$LOG_FILE"
    fi
}

debug_log "Script started with args: $*"
debug_log "Working directory: $(pwd)"
debug_log "Platform: $(uname -s)"

# Read JSON from stdin
debug_log "Reading JSON from stdin..."
JSON_INPUT=$(cat)
debug_log "JSON input received: $JSON_INPUT"

# Parse JSON fields (using simple grep/sed for portability)
debug_log "Parsing JSON fields..."
MESSAGE=$(echo "$JSON_INPUT" | grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
CWD=$(echo "$JSON_INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
SESSION_ID=$(echo "$JSON_INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
debug_log "Parsed MESSAGE: $MESSAGE"
debug_log "Parsed CWD: $CWD"
debug_log "Parsed SESSION_ID: $SESSION_ID"

# Get project name from cwd
PROJECT=""
debug_log "Determining project name..."
if [[ -n "$CWD" ]]; then
    debug_log "CWD is not empty, checking if it's a git repo..."
    # Check if it's a git repo
    if [[ -d "$CWD/.git" ]]; then
        debug_log "Found .git directory, attempting to get git remote..."
        cd "$CWD"
        PROJECT=$(basename -s .git "$(git config --get remote.origin.url 2>/dev/null || true)" 2>/dev/null || true)
        [[ -z "$PROJECT" ]] && PROJECT=$(basename "$CWD")
        debug_log "Git-based project name: $PROJECT"
    else
        debug_log "Not a git repo, using directory name"
        PROJECT=$(basename "$CWD")
        debug_log "Directory-based project name: $PROJECT"
    fi
else
    debug_log "CWD is empty, PROJECT will remain empty"
fi

# Set app name
APP_NAME="Claude Code"

# Fallback if message is empty
[[ -z "$MESSAGE" ]] && MESSAGE="Notification"

# Add session info to help identify which terminal/tab
SESSION_SHORT=""
if [[ -n "$SESSION_ID" ]]; then
    # Get last 6 chars of session ID for display
    SESSION_SHORT="${SESSION_ID: -6}"
    debug_log "Session short ID: $SESSION_SHORT"
fi

debug_log "Final values:"
debug_log "  APP_NAME: $APP_NAME"
debug_log "  PROJECT: $PROJECT"
debug_log "  MESSAGE: $MESSAGE"
debug_log "  SESSION_SHORT: $SESSION_SHORT"

# Platform-specific notification
PLATFORM="$(uname -s)"
debug_log "Detected platform: $PLATFORM"
case "$PLATFORM" in
    Darwin*)  # macOS
        if [[ -n "$PROJECT" ]]; then
            osascript -e "display notification \"$MESSAGE\" with title \"$APP_NAME\" subtitle \"$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}\""
        else
            osascript -e "display notification \"$MESSAGE\" with title \"$APP_NAME\""
        fi
        ;;

    Linux*)
        debug_log "Linux platform detected, checking if WSL..."
        # Check if WSL
        if grep -qi microsoft /proc/version 2>/dev/null; then
            debug_log "WSL detected, will use Windows toast notifications"
            # WSL - use Windows toast notifications
            if [[ -n "$PROJECT" ]]; then
                debug_log "Sending WSL notification with project: $PROJECT"
                powershell.exe -Command "
                    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                    [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

                    \$APP_ID = '$APP_NAME'
                    \$template = @\"
<toast><visual><binding template='ToastText02'>
    <text id='1'>$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}</text>
    <text id='2'>$MESSAGE</text>
</binding></visual></toast>
\"@
                    \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                    \$xml.LoadXml(\$template)
                    \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
                    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID).Show(\$toast)
                " 2>/dev/null || echo "[$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}] $MESSAGE"
            else
                debug_log "Sending WSL notification without project (message only)"
                powershell.exe -Command "
                    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                    [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

                    \$APP_ID = '$APP_NAME'
                    \$template = @\"
<toast><visual><binding template='ToastText01'>
    <text id='1'>$MESSAGE</text>
</binding></visual></toast>
\"@
                    \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                    \$xml.LoadXml(\$template)
                    \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
                    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID).Show(\$toast)
                " 2>/dev/null || echo "$MESSAGE"
            fi
        else
            # Native Linux - use notify-send
            if command -v notify-send >/dev/null 2>&1; then
                if [[ -n "$PROJECT" ]]; then
                    notify-send "<b>$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}</b>" "$MESSAGE"
                else
                    notify-send "Claude Code" "$MESSAGE"
                fi
            else
                if [[ -n "$PROJECT" ]]; then
                    echo "[$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}] $MESSAGE"
                else
                    echo "$MESSAGE"
                fi
            fi
        fi
        ;;

    CYGWIN*|MINGW*|MSYS*)  # Windows
        if [[ -n "$PROJECT" ]]; then
            powershell.exe -Command "
                [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

                \$APP_ID = '$APP_NAME'
                \$template = @\"
<toast><visual><binding template='ToastText02'>
    <text id='1'>$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}</text>
    <text id='2'>$MESSAGE</text>
</binding></visual></toast>
\"@
                \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                \$xml.LoadXml(\$template)
                \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
                [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID).Show(\$toast)
            " 2>/dev/null || echo "[$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}] $MESSAGE"
        else
            powershell.exe -Command "
                [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

                \$APP_ID = '$APP_NAME'
                \$template = @\"
<toast><visual><binding template='ToastText01'>
    <text id='1'>$MESSAGE</text>
</binding></visual></toast>
\"@
                \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                \$xml.LoadXml(\$template)
                \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
                [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID).Show(\$toast)
            " 2>/dev/null || echo "$MESSAGE"
        fi
        ;;

    *)  # Unknown OS
        if [[ -n "$PROJECT" ]]; then
            echo "[$PROJECT${SESSION_SHORT:+ ($SESSION_SHORT)}] $MESSAGE"
        else
            echo "$MESSAGE"
        fi
        ;;
esac

debug_log "Script completed"
if [[ "$DEBUG" == "true" ]]; then
    echo "[DEBUG] Log file saved to: $LOG_FILE" >&2
fi
