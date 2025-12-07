#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Show MCP Connection Guide
# ═══════════════════════════════════════════════════════════════════════════════
#
# Usage: ./scripts/show-mcp.sh
#
# Displays MCP connection configuration for:
# - Claude Desktop / Cursor
# - Environment variables for SDK
#
# ═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# Get env value
get_env_value() {
    local key="$1"
    grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | head -1 || echo ""
}

# Check .env exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found. Run 'docker compose up -d' first."
    exit 1
fi

# Load values
SUPABASE_URL=$(get_env_value "SUPABASE_PUBLIC_URL")
SERVICE_ROLE_KEY=$(get_env_value "SERVICE_ROLE_KEY")
ANON_KEY=$(get_env_value "ANON_KEY")

SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"

printf "\n"
printf "================================================================================\n"
printf "                    SUPABASE MCP CONNECTION GUIDE\n"
printf "================================================================================\n"
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
printf "\n"
