#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Show Environment Info
# ═══════════════════════════════════════════════════════════════════════════════
#
# Usage: ./scripts/show-env.sh
#
# Displays current environment configuration including:
# - Dashboard login credentials
# - Public URLs
# - API keys (ANON_KEY, SERVICE_ROLE_KEY)
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
INSTANCE_NAME=$(get_env_value "INSTANCE_NAME")
STUDIO_ORG=$(get_env_value "STUDIO_DEFAULT_ORGANIZATION")
STUDIO_PROJECT=$(get_env_value "STUDIO_DEFAULT_PROJECT")
DASHBOARD_USER=$(get_env_value "DASHBOARD_USERNAME")
DASHBOARD_PASS=$(get_env_value "DASHBOARD_PASSWORD")
SUPABASE_URL=$(get_env_value "SUPABASE_PUBLIC_URL")
SITE_URL=$(get_env_value "SITE_URL")
API_URL=$(get_env_value "API_EXTERNAL_URL")
KONG_HTTP=$(get_env_value "KONG_HTTP_PORT")
KONG_HTTPS=$(get_env_value "KONG_HTTPS_PORT")
ANON_KEY=$(get_env_value "ANON_KEY")
SERVICE_KEY=$(get_env_value "SERVICE_ROLE_KEY")

cat <<EOF

================================================================================
                    SUPABASE ENVIRONMENT INFO
================================================================================

Instance: ${INSTANCE_NAME:-supabase}

--------------------------------------------------------------------------------
DASHBOARD LOGIN
--------------------------------------------------------------------------------

  URL:      ${SUPABASE_URL:-http://localhost:8000}
  Username: ${DASHBOARD_USER:-supabase}
  Password: ${DASHBOARD_PASS}

--------------------------------------------------------------------------------
PROJECT INFO
--------------------------------------------------------------------------------

  Organization: ${STUDIO_ORG:-Default Organization}
  Project:      ${STUDIO_PROJECT:-Default Project}

--------------------------------------------------------------------------------
URLS
--------------------------------------------------------------------------------

  SUPABASE_PUBLIC_URL: ${SUPABASE_URL:-http://localhost:8000}
  SITE_URL:            ${SITE_URL:-http://localhost:3000}
  API_EXTERNAL_URL:    ${API_URL:-http://localhost:8000}
  KONG_HTTP_PORT:      ${KONG_HTTP:-8000}
  KONG_HTTPS_PORT:     ${KONG_HTTPS:-8443}

--------------------------------------------------------------------------------
API KEYS (copy these for your app)
--------------------------------------------------------------------------------

ANON_KEY:
${ANON_KEY}

SERVICE_ROLE_KEY:
${SERVICE_KEY}

================================================================================

EOF
