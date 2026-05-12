#!/usr/bin/env bash
# DeepChem MolAI local startup script
# Usage: bash start.sh

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "=== DeepChem MolAI: Starting backend on port 8282 ==="
cd "$ROOT"
uvicorn mock_backend:app --host 0.0.0.0 --port 8282 &
BACKEND_PID=$!

echo "=== DeepChem MolAI: Starting frontend on port 3000 ==="
cd "$ROOT/mol_app/build/web"
python -m http.server 3000 &
FRONTEND_PID=$!

echo ""
echo "  App:   http://localhost:3000"
echo "  API:   http://localhost:8282/docs"
echo ""
echo "Press Ctrl+C to stop both servers."

trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit 0" INT TERM
wait
