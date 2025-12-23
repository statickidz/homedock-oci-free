#!/bin/bash

# Ensure we're running as root
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Add ubuntu SSH authorized keys to the root user
mkdir -p /root/.ssh
cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/
chown root:root /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Add ubuntu user to sudoers
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# OpenSSH
apt install -y openssh-server
systemctl status sshd

# Permit root login
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Log everything
exec > >(tee -a /var/log/homedock-install.log)
exec 2>&1

echo "=== Starting HomeDock OS setup at $(date) ==="

# Setup log viewer server
echo "Setting up installation log viewer..."

# Create directories
mkdir -p /tmp
mkdir -p /usr/local/bin

# Create HTML file for log viewer
cat > /tmp/log-viewer.html << 'EOFHTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HomeDock Installation Logs</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Courier New', monospace;
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1 {
            color: #4ec9b0;
            margin-bottom: 10px;
            font-size: 24px;
        }
        .status {
            padding: 10px;
            background: #2d2d2d;
            border-left: 4px solid #4ec9b0;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        .status.completed {
            border-left-color: #4ec9b0;
            background: #1e3a1e;
        }
        .log-container {
            background: #252526;
            border: 1px solid #3e3e42;
            border-radius: 4px;
            padding: 15px;
            max-height: 80vh;
            overflow-y: auto;
            font-size: 13px;
            line-height: 1.6;
        }
        .log-line {
            margin-bottom: 2px;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        .log-line:last-child {
            margin-bottom: 0;
        }
        .loading {
            color: #858585;
            font-style: italic;
        }
        .error {
            color: #f48771;
        }
        ::-webkit-scrollbar {
            width: 10px;
        }
        ::-webkit-scrollbar-track {
            background: #1e1e1e;
        }
        ::-webkit-scrollbar-thumb {
            background: #424242;
            border-radius: 5px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: #4e4e4e;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 HomeDock Installation</h1>
        <div id="status" class="status">
            <strong>Status:</strong> <span id="status-text">Installing...</span>
        </div>
        <div class="log-container" id="log-container">
            <div class="loading">Loading logs...</div>
        </div>
    </div>
    <script>
        const logContainer = document.getElementById('log-container');
        const statusText = document.getElementById('status-text');
        const statusDiv = document.getElementById('status');
        let isCompleted = false;

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function updateLogs() {
            fetch('/logs')
                .then(response => {
                    if (!response.ok) throw new Error('Failed to fetch logs');
                    return response.text();
                })
                .then(data => {
                    if (data.trim()) {
                        const lines = data.split('\n');
                        logContainer.innerHTML = lines.map(line => 
                            `<div class="log-line">${escapeHtml(line)}</div>`
                        ).join('');
                        
                        // Auto-scroll to bottom
                        logContainer.scrollTop = logContainer.scrollHeight;
                        
                        // Check for completion
                        if (data.includes('HomeDock OS setup completed') && !isCompleted) {
                            isCompleted = true;
                            statusText.textContent = 'Installation completed! The log viewer will close shortly...';
                            statusDiv.classList.add('completed');
                            
                            // Stop polling after a delay
                            setTimeout(() => {
                                statusText.textContent = 'Installation completed. Redirecting to HomeDock...';
                                setTimeout(() => {
                                    window.location.reload();
                                }, 3000);
                            }, 2000);
                        }
                    } else {
                        logContainer.innerHTML = '<div class="loading">Waiting for logs...</div>';
                    }
                })
                .catch(error => {
                    logContainer.innerHTML = `<div class="error">Error: ${escapeHtml(error.message)}</div>`;
                });
        }

        // Update logs every 2 seconds
        updateLogs();
        setInterval(updateLogs, 2000);
    </script>
</body>
</html>
EOFHTML

# Create log viewer server script
cat > /usr/local/bin/log-viewer-server.sh << 'EOFSERVER'
#!/bin/bash

# Simple HTTP server for HomeDock installation log viewer
# Runs on port 80 and automatically stops when installation completes

LOG_FILE="/var/log/homedock-install.log"
HTML_FILE="/tmp/log-viewer.html"
PORT=80
COMPLETION_PATTERN="HomeDock OS setup completed"

# Function to handle HTTP request
# Reads from stdin and writes response to stdout
handle_request() {
    # Read the request line
    read -r request_line || return 1
    
    # Skip remaining headers (read until empty line)
    while IFS= read -r line && [ -n "$line" ]; do
        : # Skip headers
    done
    
    # Parse request
    local method=$(echo "$request_line" | awk '{print $1}')
    local path=$(echo "$request_line" | awk '{print $2}')
    
    # Remove query string if present
    path=$(echo "$path" | cut -d'?' -f1)
    
    # Send response (use printf for proper HTTP formatting)
    if [ "$path" = "/" ] || [ -z "$path" ]; then
        # Serve HTML
        printf "HTTP/1.1 200 OK\r\n"
        printf "Content-Type: text/html; charset=utf-8\r\n"
        printf "Connection: close\r\n"
        printf "\r\n"
        cat "$HTML_FILE"
    elif [ "$path" = "/logs" ]; then
        # Serve log content
        printf "HTTP/1.1 200 OK\r\n"
        printf "Content-Type: text/plain; charset=utf-8\r\n"
        printf "Access-Control-Allow-Origin: *\r\n"
        printf "Connection: close\r\n"
        printf "\r\n"
        if [ -f "$LOG_FILE" ]; then
            cat "$LOG_FILE"
        else
            echo "Log file not found yet..."
        fi
    else
        # 404 Not Found
        printf "HTTP/1.1 404 Not Found\r\n"
        printf "Content-Type: text/plain\r\n"
        printf "Connection: close\r\n"
        printf "\r\n"
        echo "404 Not Found"
    fi
}

# Function to check if installation is complete
check_completion() {
    if [ -f "$LOG_FILE" ]; then
        if grep -q "$COMPLETION_PATTERN" "$LOG_FILE" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Start server
echo "Starting log viewer server on port $PORT..." >&2
echo "HTML file: $HTML_FILE" >&2
echo "Log file: $LOG_FILE" >&2
[ -f "$HTML_FILE" ] && echo "HTML file exists" >&2 || echo "ERROR: HTML file not found!" >&2
[ -f "$LOG_FILE" ] && echo "Log file exists" >&2 || echo "Log file not found yet (will be created)" >&2
echo "Access at http://$(hostname -I | awk '{print $1}')" >&2

# Start completion monitor in background
(
    while true; do
        sleep 5
        if check_completion; then
            echo "Installation completed. Stopping log viewer server..."
            # Kill this script (and thus the server)
            kill $$ 2>/dev/null
            break
        fi
    done
) &
MONITOR_PID=$!

# Cleanup function
cleanup() {
    kill $MONITOR_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM EXIT

# Simple HTTP server - use the most reliable method available
# Priority: socat > netcat with exec > pure bash /dev/tcp

# Create handler function as a separate script for execution
HANDLER_SCRIPT="/tmp/http-handler.sh"
cat > "$HANDLER_SCRIPT" << 'EOFHANDLER'
#!/bin/bash
LOG_FILE="/var/log/homedock-install.log"
HTML_FILE="/tmp/log-viewer.html"

# Read request line
read -r request_line 2>/dev/null || exit 1

# Skip headers until empty line
while IFS= read -r line 2>/dev/null && [ -n "$line" ]; do
    : # Skip headers
done

# Parse path from request
path=$(echo "$request_line" | awk '{print $2}' | cut -d'?' -f1)

# Send HTTP response
if [ "$path" = "/" ] || [ -z "$path" ]; then
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: text/html; charset=utf-8\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    [ -f "$HTML_FILE" ] && cat "$HTML_FILE" || echo "<html><body><h1>HTML file not found</h1></body></html>"
elif [ "$path" = "/logs" ]; then
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: text/plain; charset=utf-8\r\n"
    printf "Access-Control-Allow-Origin: *\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    [ -f "$LOG_FILE" ] && cat "$LOG_FILE" || echo "Log file not found yet..."
else
    printf "HTTP/1.1 404 Not Found\r\n"
    printf "Content-Type: text/plain\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    echo "404 Not Found"
fi
EOFHANDLER
chmod +x "$HANDLER_SCRIPT"

# Try different server methods
if command -v socat >/dev/null 2>&1; then
    # Method 1: socat (best option - handles connections properly)
    echo "Using socat to listen on port $PORT..." >&2
    socat TCP-LISTEN:$PORT,reuseaddr,fork EXEC:"$HANDLER_SCRIPT" 2>&1
elif command -v nc >/dev/null 2>&1; then
    # Method 2: netcat with exec support
    echo "Using netcat to listen on port $PORT..." >&2
    # Check if netcat supports -e or -c (execute command)
    if nc -h 2>&1 | grep -qE "\-e"; then
        # OpenBSD netcat with -e
        while true; do
            nc -l -p $PORT -e "$HANDLER_SCRIPT" 2>&1 || break
            sleep 0.1
        done
    elif nc -h 2>&1 | grep -qE "\-c"; then
        # GNU netcat with -c
        while true; do
            nc -l -p $PORT -c "$HANDLER_SCRIPT" 2>&1 || break
            sleep 0.1
        done
    else
        # Method 3: netcat without exec - this is problematic
        # Without -e/-c, we can't easily read request and write response on same connection
        echo "ERROR: Netcat doesn't support -e/-c options needed for HTTP server." >&2
        echo "Attempting to install socat (more reliable for this use case)..." >&2
        # Try to install socat
        if command -v apt-get >/dev/null 2>&1; then
            while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ||
                fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
                sleep 1
            done
            apt-get update -qq >/dev/null 2>&1
            if apt-get install -y socat >/dev/null 2>&1; then
                echo "socat installed successfully. Restarting with socat..." >&2
                # Restart with socat
                socat TCP-LISTEN:$PORT,reuseaddr,fork EXEC:"$HANDLER_SCRIPT" 2>&1
            else
                echo "Failed to install socat. HTTP server cannot start without -e/-c support." >&2
                exit 1
            fi
        else
            echo "Cannot install socat. HTTP server requires netcat with -e/-c or socat." >&2
            exit 1
        fi
    fi
else
    echo "ERROR: Neither 'nc' nor 'socat' is available. Cannot start HTTP server." >&2
    exit 1
fi
EOFSERVER

# Make server script executable
chmod +x /usr/local/bin/log-viewer-server.sh

# Install netcat or socat if not available (lightweight, quick install)
# Do this early and wait for package manager if needed
if ! command -v nc >/dev/null 2>&1 && ! command -v socat >/dev/null 2>&1; then
    echo "Installing netcat or socat for log viewer server..."
    # Wait for package manager if needed
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ||
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        echo "Waiting for package manager to install network tools..."
        sleep 2
    done
    apt update -qq 2>&1
    # Try to install socat first (better for this use case), then netcat as fallback
    if ! apt install -y socat 2>&1; then
        echo "socat not available, trying netcat..." >&2
        apt install -y netcat-openbsd 2>&1 || apt install -y netcat 2>&1 || {
            echo "Warning: Failed to install netcat/socat. Log viewer may not work." >&2
        }
    fi
fi

# Verify netcat is available
if ! command -v nc >/dev/null 2>&1 && ! command -v socat >/dev/null 2>&1; then
    echo "ERROR: Neither netcat nor socat is available. Log viewer cannot start."
else
    # Start log viewer server in background
    # Redirect output to a log file so we can debug
    echo "Starting log viewer server on port 80..."
    /usr/local/bin/log-viewer-server.sh >> /var/log/log-viewer-server.log 2>&1 &
    LOG_VIEWER_PID=$!
    
    # Give server a moment to start
    sleep 3
    
    # Verify server is running and listening on port 80
    sleep 2  # Give it more time to start
    if ps -p $LOG_VIEWER_PID > /dev/null 2>&1; then
        # Check if it's actually listening
        LISTENING=false
        if command -v ss >/dev/null 2>&1; then
            if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
                LISTENING=true
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
                LISTENING=true
            fi
        fi
        
        if [ "$LISTENING" = "true" ]; then
            echo "✓ Log viewer server started successfully (PID: $LOG_VIEWER_PID) and listening on port $PORT"
        else
            echo "⚠ WARNING: Server process is running (PID: $LOG_VIEWER_PID) but may not be listening on port $PORT"
            echo "  This might mean netcat doesn't support -e/-c options. Trying to install socat..."
            # Try to install socat as it's more reliable
            if ! command -v socat >/dev/null 2>&1; then
                while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ||
                    fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
                    sleep 1
                done
                apt install -y socat >/dev/null 2>&1 && {
                    echo "  socat installed. Restarting server..."
                    kill $LOG_VIEWER_PID 2>/dev/null
                    sleep 1
                    /usr/local/bin/log-viewer-server.sh >> /var/log/log-viewer-server.log 2>&1 &
                    LOG_VIEWER_PID=$!
                    sleep 2
                }
            fi
        fi
        echo "Access installation logs at: http://$(hostname -I | awk '{print $1}')"
        echo "Server logs: /var/log/log-viewer-server.log"
    else
        echo "✗ ERROR: Log viewer server failed to start. Check /var/log/log-viewer-server.log for details"
        if [ -f /var/log/log-viewer-server.log ]; then
            echo "Last 10 lines of server log:"
            tail -10 /var/log/log-viewer-server.log
        fi
    fi
fi

# Wait for system to be ready
sleep 30

# Wait for package manager to be available
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ||
    fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for package manager..."
    sleep 5
done

# Update package lists first
apt update -y

# Check if the /opt/ directory exists
if [ ! -d "/opt/" ]; then
    mkdir -p /opt/
fi

# Change to the /opt/ directory
cd /opt/

# Allow all traffic
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables --flush

# Save iptables rules
apt install -y netfilter-persistent
netfilter-persistent save

# Install HomeDockOS > pseudo-TTY
echo "Installing HomeDock OS..."
script -qec "curl -fsSL https://get.homedock.cloud | bash" /dev/null

echo "=== HomeDock OS setup completed at $(date) ==="
