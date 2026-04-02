#!/bin/bash

# Finmate iOS Build Script
# Builds the app with environment variables injected via --dart-define

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${GREEN}🚀 Building Finmate for iOS...${NC}"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "${RED}❌ Error: .env file not found${NC}"
    echo "Please create a .env file with your environment variables"
    exit 1
fi

# Load environment variables from .env
export $(grep -v '^#' .env | xargs)

# Validate required variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "${RED}❌ Error: Missing required environment variables${NC}"
    echo "Required: SUPABASE_URL, SUPABASE_ANON_KEY"
    exit 1
fi

echo "${GREEN}✓ Environment variables loaded${NC}"

# Build arguments
BUILD_ARGS=(
    "--dart-define=SUPABASE_URL=$SUPABASE_URL"
    "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
    "--dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY"
    "--dart-define=STRIPE_MONTHLY_PRICE_ID=$STRIPE_MONTHLY_PRICE_ID"
    "--dart-define=STRIPE_ANNUAL_PRICE_ID=$STRIPE_ANNUAL_PRICE_ID"
    "--dart-define=SENTRY_DSN=$SENTRY_DSN"
    "--dart-define=ENVIRONMENT=$ENVIRONMENT"
)

# Run flutter build
echo "${YELLOW}Building IPA...${NC}"
flutter build ipa --release "${BUILD_ARGS[@]}"

if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Build successful!${NC}"
    echo "IPA location: build/ios/ipa/finmate.ipa"
else
    echo "${RED}❌ Build failed${NC}"
    exit 1
fi
