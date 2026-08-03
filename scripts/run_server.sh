#!/usr/bin/env bash
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   🚀 FedChat FL Server Launcher & Docker Manager   ${NC}"
echo -e "${CYAN}====================================================${NC}"

# Navigate to project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH. Please install Docker first.${NC}"
    exit 1
fi

# Ensure .env file exists in server/
SERVER_DIR="$PROJECT_ROOT/server"
if [ ! -f "$SERVER_DIR/.env" ]; then
    echo -e "${YELLOW}⚠️  server/.env file not found. Creating from server/.env.example...${NC}"
    cp "$SERVER_DIR/.env.example" "$SERVER_DIR/.env"
    echo -e "${GREEN}✓ Created server/.env file.${NC}"
fi

echo -e "\n${YELLOW}📦 Building and launching Docker services (FastAPI, Postgres, Redis)...${NC}"
docker compose -f "$SERVER_DIR/docker-compose.yml" up --build -d

echo -e "\n${YELLOW}⏳ Waiting for backend services to pass health checks...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || true)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e "${GREEN}✅ Server is HEALTHY and running at http://localhost:8000!${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo -n "."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "\n${RED}❌ Server health check timed out. Displaying Docker logs:${NC}"
    docker compose -f "$SERVER_DIR/docker-compose.yml" logs api
    exit 1
fi

echo -e "\n${CYAN}📊 Service Status:${NC}"
docker compose -f "$SERVER_DIR/docker-compose.yml" ps

echo -e "\n${GREEN}🎉 Backend setup complete!${NC}"
echo -e "  • FastAPI Endpoint : ${CYAN}http://localhost:8000/api/v1${NC}"
echo -e "  • OpenAPI Docs     : ${CYAN}http://localhost:8000/api/v1/openapi.json${NC}"
echo -e "  • Health Check     : ${CYAN}http://localhost:8000/health${NC}"
echo -e "  • Tail Server Logs : ${YELLOW}docker compose -f server/docker-compose.yml logs -f api${NC}"
echo -e "  • Stop Server      : ${YELLOW}docker compose -f server/docker-compose.yml down${NC}"
