#!/bin/bash

# Ensure we're running as root
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

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
handle_request() {
    local request_line
    read -r request_line
    
    # Parse request
    local method=$(echo "$request_line" | awk '{print $1}')
    local path=$(echo "$request_line" | awk '{print $2}')
    
    # Remove query string if present
    path=$(echo "$path" | cut -d'?' -f1)
    
    if [ "$path" = "/" ] || [ "$path" = "" ]; then
        # Serve HTML
        {
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: text/html; charset=utf-8"
            echo "Connection: close"
            echo ""
            cat "$HTML_FILE"
        }
    elif [ "$path" = "/logs" ]; then
        # Serve log content
        if [ -f "$LOG_FILE" ]; then
            {
                echo "HTTP/1.1 200 OK"
                echo "Content-Type: text/plain; charset=utf-8"
                echo "Access-Control-Allow-Origin: *"
                echo "Connection: close"
                echo ""
                cat "$LOG_FILE"
            }
        else
            {
                echo "HTTP/1.1 200 OK"
                echo "Content-Type: text/plain; charset=utf-8"
                echo "Connection: close"
                echo ""
                echo "Log file not found yet..."
            }
        fi
    else
        # 404 Not Found
        {
            echo "HTTP/1.1 404 Not Found"
            echo "Content-Type: text/plain"
            echo "Connection: close"
            echo ""
            echo "404 Not Found"
        }
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
echo "Starting log viewer server on port $PORT..."
echo "Access at http://$(hostname -I | awk '{print $1}')"

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

# Simple HTTP server using netcat (preferred) or socat
if command -v nc >/dev/null 2>&1; then
    # Use netcat in a loop - simple and reliable
    while true; do
        nc -l -p $PORT -q 0 2>/dev/null | handle_request || break
    done
elif command -v socat >/dev/null 2>&1; then
    # Fallback to socat - create inline handler
    socat TCP-LISTEN:$PORT,reuseaddr,fork SYSTEM:"bash -c 'read request_line; method=\$(echo \$request_line | awk \"{print \\\$1}\"); path=\$(echo \$request_line | awk \"{print \\\$2}\" | cut -d\"?\" -f1); if [ \"\$path\" = \"/\" ] || [ -z \"\$path\" ]; then echo -e \"HTTP/1.1 200 OK\\r\\nContent-Type: text/html; charset=utf-8\\r\\nConnection: close\\r\\n\\r\"; cat $HTML_FILE; elif [ \"\$path\" = \"/logs\" ]; then echo -e \"HTTP/1.1 200 OK\\r\\nContent-Type: text/plain; charset=utf-8\\r\\nAccess-Control-Allow-Origin: *\\r\\nConnection: close\\r\\n\\r\"; [ -f $LOG_FILE ] && cat $LOG_FILE || echo \"Log file not found yet...\"; else echo -e \"HTTP/1.1 404 Not Found\\r\\nContent-Type: text/plain\\r\\nConnection: close\\r\\n\\r\\n404 Not Found\"; fi'" 2>/dev/null
else
    echo "Error: Neither 'nc' nor 'socat' is available. Please install one of them."
    exit 1
fi
EOFSERVER

# Make server script executable
chmod +x /usr/local/bin/log-viewer-server.sh

# Install netcat if not available (lightweight, quick install)
if ! command -v nc >/dev/null 2>&1 && ! command -v socat >/dev/null 2>&1; then
    echo "Installing netcat for log viewer server..."
    apt update -qq && apt install -y netcat-openbsd >/dev/null 2>&1 || apt install -y netcat >/dev/null 2>&1 || true
fi

# Start log viewer server in background
echo "Starting log viewer server on port 80..."
/usr/local/bin/log-viewer-server.sh >/dev/null 2>&1 &
LOG_VIEWER_PID=$!
echo "Log viewer server started (PID: $LOG_VIEWER_PID)"
echo "Access installation logs at: http://$(hostname -I | awk '{print $1}')"

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
