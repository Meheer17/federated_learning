#!/usr/bin/env bash
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   📱 FedChat Mobile App Launcher (ADB & Flutter)   ${NC}"
echo -e "${CYAN}====================================================${NC}"

# Navigate to project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter SDK is not installed or not in PATH.${NC}"
    exit 1
fi

# Check ADB installation
if ! command -v adb &> /dev/null; then
    echo -e "${YELLOW}⚠️  ADB is not found in PATH. Make sure Android SDK platform-tools are installed.${NC}"
fi

# Detect connected ADB devices
echo -e "\n${YELLOW}🔍 Checking connected devices...${NC}"
flutter devices

if command -v adb &> /dev/null; then
    DEVICES=$(adb devices | grep -v "List of devices attached" | grep "device" | awk '{print $1}')
    if [ -n "$DEVICES" ]; then
        echo -e "\n${GREEN}📱 Found connected ADB device(s):${NC}"
        echo "$DEVICES"
        
        # Set up port forwarding so mobile app can reach host server on http://localhost:8000
        for DEV in $DEVICES; do
            echo -e "${CYAN}🔗 Setting up ADB reverse port forwarding (8000 -> 8000) for device $DEV...${NC}"
            adb -s "$DEV" reverse tcp:8000 tcp:8000 || true
        done
        echo -e "${GREEN}✓ Reverse port forwarding active. The mobile app can reach server at http://localhost:8000${NC}"
    else
        echo -e "${YELLOW}⚠️  No physical ADB devices detected. Will look for active emulators/desktop targets.${NC}"
    fi
fi

# Run flutter pub get
echo -e "\n${YELLOW}📦 Fetching Flutter dependencies...${NC}"
flutter pub get

# Launch Flutter app
echo -e "\n${GREEN}🚀 Launching FedChat on connected device...${NC}"
echo -e "${CYAN}Press 'r' for Hot Reload, 'R' for Hot Restart, 'q' to quit.${NC}\n"

flutter run
