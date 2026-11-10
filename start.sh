#!/bin/bash
# Uruchamia Intervals (8001), Fitatu (8002) i Caddy (PORT). Gdy ktorykolwiek proces padnie, konczy kontener.
set -u

pids=()
start() { "$@" & pids+=("$!"); }

# Kazdy serwer dostaje tylko swoje sekrety.
# Intervals: FASTMCP_HOST=0.0.0.0, zeby SDK mcp nie wlaczylo ochrony Host (421 dla Host: *.onrender.com).
# Port 8001 nie jest wystawiony publicznie, Render kieruje ruch tylko na $PORT.
start env -u FITATU_EMAIL -u FITATU_PASSWORD -u MCP_AUTH_PASSWORD -u MCP_PUBLIC_URL -u PORT -u HOST \
    MCP_TRANSPORT=http FASTMCP_HOST=0.0.0.0 FASTMCP_PORT=8001 \
    /opt/venv/bin/python -m intervals_mcp_server.server

# Fitatu: PORT/HOST nadpisane, bo Render ustawia PORT dla Caddy.
start env -u API_KEY -u ATHLETE_ID \
    MCP_TRANSPORT=http HOST=127.0.0.1 PORT=8002 NODE_ENV=production \
    /usr/local/bin/node /app/fitatu/dist/index.js

start caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

stop() { kill "${pids[@]}" 2>/dev/null; wait; }
trap 'stop; exit 0' TERM INT

wait -n
code=$?
echo "start.sh: jeden z procesow zakonczyl sie (kod $code), zatrzymuje kontener" >&2
stop
exit 1
