#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Supabase MCP Connection Guide
# ═══════════════════════════════════════════════════════════════════════════════
#
# This script displays MCP connection information in container logs.
# View this via: docker logs supabase-mcp-guide
#
# The keys shown are dynamically loaded from .env file.
#
# ═══════════════════════════════════════════════════════════════════════════════

ENV_FILE="/app/.env"

# Get env value
get_env_value() {
    local key="$1"
    grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | head -1 || echo ""
}

# Wait for .env to be ready
wait_for_env() {
    local retries=30
    while [[ ! -f "$ENV_FILE" ]] && [[ $retries -gt 0 ]]; do
        echo "[MCP] Waiting for initialization..."
        sleep 2
        retries=$((retries - 1))
    done
    
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "[MCP] ERROR: .env file not found after timeout"
        exit 1
    fi
}

print_connection_info() {
    local SUPABASE_URL=$(get_env_value "SUPABASE_PUBLIC_URL")
    local SERVICE_ROLE_KEY=$(get_env_value "SERVICE_ROLE_KEY")
    local ANON_KEY=$(get_env_value "ANON_KEY")
    
    SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"

    printf "\n"
    printf "================================================================================\n"
    printf "                    SUPABASE MCP CONNECTION GUIDE\n"
    printf "================================================================================\n"
    printf "\n"
    printf "Keys loaded from .env (auto-generated on first deployment)\n"
    printf "\n"
    printf "--------------------------------------------------------------------------------\n"
    printf "CLAUDE DESKTOP / CURSOR CONFIGURATION\n"
    printf "--------------------------------------------------------------------------------\n"
    printf "\n"
    printf "Add this to your claude_desktop_config.json or .cursor/mcp.json:\n"
    printf "\n"
    printf '{\n'
    printf '  "mcpServers": {\n'
    printf '    "supabase": {\n'
    printf '      "command": "npx",\n'
    printf '      "args": [\n'
    printf '        "-y",\n'
    printf '        "@supabase/mcp-server-supabase@latest",\n'
    printf '        "--supabase-url", "<SUPABASE_URL>",\n'
    printf '        "--supabase-key", "<SERVICE_ROLE_KEY>"\n'
    printf '      ]\n'
    printf '    }\n'
    printf '  }\n'
    printf '}\n'
    printf "\n"
    printf "Replace <SUPABASE_URL> and <SERVICE_ROLE_KEY> with the values below.\n"
    printf "\n"
    printf "--------------------------------------------------------------------------------\n"
    printf "SDK CONFIGURATION\n"
    printf "--------------------------------------------------------------------------------\n"
    printf "\n"
    printf "JavaScript/TypeScript:\n"
    printf "  npm install @supabase/supabase-js\n"
    printf "\n"
    printf "  import { createClient } from '@supabase/supabase-js'\n"
    printf '  const supabase = createClient("<SUPABASE_URL>", "<ANON_KEY>")\n'
    printf "\n"
    printf "Python:\n"
    printf "  pip install supabase\n"
    printf "\n"
    printf "  from supabase import create_client\n"
    printf '  supabase = create_client("<SUPABASE_URL>", "<ANON_KEY>")\n'
    printf "\n"
    printf "--------------------------------------------------------------------------------\n"
    printf "COPY THESE VALUES\n"
    printf "--------------------------------------------------------------------------------\n"
    printf "\n"
    printf "SUPABASE_URL:\n"
    printf "%s\n" "$SUPABASE_URL"
    printf "\n"
    printf "SUPABASE_ANON_KEY:\n"
    printf "%s\n" "$ANON_KEY"
    printf "\n"
    printf "SERVICE_ROLE_KEY:\n"
    printf "%s\n" "$SERVICE_ROLE_KEY"
    printf "\n"
    printf "WARNING: Keep SERVICE_ROLE_KEY secret! It bypasses Row Level Security.\n"
    printf "\n"
    printf "================================================================================\n"
    printf "           Connection info refreshes every 5 minutes\n"
    printf "================================================================================\n"
    printf "\n"
}

main() {
    wait_for_env
    
    # Initial print
    print_connection_info
    
    # Watch for .env changes using inotify (falls back to polling if unavailable)
    if command -v inotifywait &> /dev/null; then
        echo "[MCP] Watching for .env changes (inotify)..."
        while true; do
            inotifywait -qq -e modify -e close_write "$ENV_FILE" 2>/dev/null
            sleep 1  # Brief delay to avoid rapid updates
            print_connection_info
        done
    else
        echo "[MCP] inotifywait not available, falling back to 5-minute polling..."
        while true; do
            sleep 300
            print_connection_info
        done
    fi
}

main
