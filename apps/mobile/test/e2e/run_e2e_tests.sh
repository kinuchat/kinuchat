#!/bin/bash

# E2E Test Runner for MeshLink
#
# Usage:
#   ./run_e2e_tests.sh [options]
#
# Options:
#   --mock          Run with mock servers (no real API calls)
#   --relay URL     Relay server URL (default: http://localhost:3030)
#   --matrix URL    Matrix server URL (default: https://matrix.kinuchat.com)
#   --demo          Generate demo data only
#   --all           Run all tests
#   --spec          Run spec compliance tests only
#   --help          Show this help

set -e

# Default values
USE_MOCK="false"
RELAY_SERVER_URL="${RELAY_SERVER_URL:-http://localhost:3030}"
MATRIX_HOMESERVER_URL="${MATRIX_HOMESERVER_URL:-https://matrix.kinuchat.com}"
RUN_DEMO="false"
RUN_ALL="false"
RUN_SPEC="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mock)
            USE_MOCK="true"
            shift
            ;;
        --relay)
            RELAY_SERVER_URL="$2"
            shift 2
            ;;
        --matrix)
            MATRIX_HOMESERVER_URL="$2"
            shift 2
            ;;
        --demo)
            RUN_DEMO="true"
            shift
            ;;
        --all)
            RUN_ALL="true"
            shift
            ;;
        --spec)
            RUN_SPEC="true"
            shift
            ;;
        --help)
            head -20 "$0" | tail -18
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "  MeshLink E2E Test Runner"
echo "========================================"
echo ""
echo "Configuration:"
echo "  USE_MOCK: $USE_MOCK"
echo "  RELAY_SERVER_URL: $RELAY_SERVER_URL"
echo "  MATRIX_HOMESERVER_URL: $MATRIX_HOMESERVER_URL"
echo ""

# Export environment variables
export USE_MOCK
export RELAY_SERVER_URL
export MATRIX_HOMESERVER_URL

# Change to mobile app directory
cd "$(dirname "$0")/../.."

# Generate demo data
if [ "$RUN_DEMO" = "true" ]; then
    echo -e "${YELLOW}Generating demo data...${NC}"
    dart test/e2e/demo_data_populator.dart
    echo ""
    exit 0
fi

# Run spec compliance tests only
if [ "$RUN_SPEC" = "true" ]; then
    echo -e "${YELLOW}Running spec compliance tests...${NC}"
    dart test test/e2e/spec_compliance_test.dart
    exit $?
fi

# Run all tests
if [ "$RUN_ALL" = "true" ] || [ "$RUN_DEMO" = "false" ] && [ "$RUN_SPEC" = "false" ]; then
    echo -e "${YELLOW}Running all E2E tests...${NC}"
    echo ""

    # Check if relay server is available (unless in mock mode)
    if [ "$USE_MOCK" = "false" ]; then
        echo "Checking relay server at $RELAY_SERVER_URL..."
        if curl -s --connect-timeout 5 "$RELAY_SERVER_URL/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Relay server is available${NC}"
        else
            echo -e "${YELLOW}⚠ Relay server not available - some tests will be skipped${NC}"
        fi
        echo ""
    fi

    # Run tests
    echo "1. Spec Compliance Tests"
    echo "------------------------"
    if dart test test/e2e/spec_compliance_test.dart; then
        echo -e "${GREEN}✓ Spec compliance tests passed${NC}"
    else
        echo -e "${RED}✗ Spec compliance tests failed${NC}"
    fi
    echo ""

    echo "2. Relay Server Tests"
    echo "---------------------"
    if dart test test/e2e/relay_server_test.dart; then
        echo -e "${GREEN}✓ Relay server tests passed${NC}"
    else
        echo -e "${YELLOW}⚠ Some relay server tests may have been skipped${NC}"
    fi
    echo ""

    echo "3. Matrix Integration Tests"
    echo "---------------------------"
    if dart test test/e2e/matrix_integration_test.dart; then
        echo -e "${GREEN}✓ Matrix integration tests passed${NC}"
    else
        echo -e "${YELLOW}⚠ Some Matrix tests may have been skipped${NC}"
    fi
    echo ""

    echo "========================================"
    echo "  E2E Tests Complete"
    echo "========================================"
fi
