#!/bin/bash
# HexStrike AI Docker Entrypoint
# Runs both the Flask API server and MCP SSE server concurrently

set -e

# Configuration with environment variable overrides
HEXSTRIKE_HOST="${HEXSTRIKE_HOST:-127.0.0.1}"
HEXSTRIKE_PORT="${HEXSTRIKE_PORT:-8899}"
MCP_TRANSPORT="${MCP_TRANSPORT:-sse}"
MCP_HOST="${MCP_HOST:-0.0.0.0}"
MCP_PORT="${MCP_PORT:-9010}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 HexStrike AI - Docker Container Starting               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  📡 API Server:  http://${HEXSTRIKE_HOST}:${HEXSTRIKE_PORT}                      ║"
echo "║  🔄 MCP Server:  http://${MCP_HOST}:${MCP_PORT} (${MCP_TRANSPORT} transport)    ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Function to handle shutdown gracefully
shutdown() {
    echo "🛑 Shutting down HexStrike AI services..."
    kill -TERM $API_PID $MCP_PID 2>/dev/null
    wait $API_PID $MCP_PID 2>/dev/null
    echo "✅ HexStrike AI services stopped."
    exit 0
}

trap shutdown SIGTERM SIGINT SIGQUIT

# Start the Flask API server in the background
echo "🚀 Starting HexStrike AI API Server on ${HEXSTRIKE_HOST}:${HEXSTRIKE_PORT}..."
python3 hexstrike_server.py &
API_PID=$!

# Wait briefly for API server to start
sleep 3

# Start the MCP SSE server in the background
echo "🚀 Starting HexStrike AI MCP Server (${MCP_TRANSPORT}) on ${MCP_HOST}:${MCP_PORT}..."
python3 hexstrike_mcp.py \
    --server "http://127.0.0.1:${HEXSTRIKE_PORT}" \
    --transport "${MCP_TRANSPORT}" \
    --host "${MCP_HOST}" \
    --port "${MCP_PORT}" &
MCP_PID=$!

echo "✅ Both services are running:"
echo "   ├─ API Server (PID ${API_PID}): http://${HEXSTRIKE_HOST}:${HEXSTRIKE_PORT}"
echo "   └─ MCP Server (PID ${MCP_PID}): http://${MCP_HOST}:${MCP_PORT} (${MCP_TRANSPORT})"

# Wait for either process to exit
wait -n $API_PID $MCP_PID 2>/dev/null || true

# If one process dies, shut down the other
echo "⚠️  One of the services has stopped. Shutting down..."
shutdown