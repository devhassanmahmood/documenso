#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Heroku Deployment Script${NC}"

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo -e "${RED}❌ Heroku CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi

# Check if user is logged in to Heroku
if ! heroku auth:whoami &> /dev/null; then
    echo -e "${YELLOW}🔐 Please log in to Heroku...${NC}"
    heroku login
fi

# Get app name from user
read -p "Enter your Heroku app name: " APP_NAME

if [ -z "$APP_NAME" ]; then
    echo -e "${RED}❌ App name is required.${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Setting up Heroku app: $APP_NAME${NC}"

# Create app if it doesn't exist
if ! heroku apps:info --app "$APP_NAME" &> /dev/null; then
    echo -e "${YELLOW}Creating new Heroku app...${NC}"
    heroku create "$APP_NAME"
else
    echo -e "${GREEN}✅ App already exists.${NC}"
fi

# Add PostgreSQL addon
echo -e "${YELLOW}🗄️  Adding PostgreSQL addon...${NC}"
heroku addons:create heroku-postgresql:mini --app "$APP_NAME"

# Add Redis addon (optional)
read -p "Do you want to add Redis addon? (y/n): " ADD_REDIS
if [[ $ADD_REDIS =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🔴 Adding Redis addon...${NC}"
    heroku addons:create heroku-redis:mini --app "$APP_NAME"
fi

echo -e "${GREEN}✅ Addons configured.${NC}"

# Generate secrets
echo -e "${YELLOW}🔐 Generating secrets...${NC}"
NEXTAUTH_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -base64 32)
SECONDARY_KEY=$(openssl rand -base64 32)

# Set environment variables
echo -e "${YELLOW}⚙️  Setting environment variables...${NC}"

# Authentication
heroku config:set NEXTAUTH_SECRET="$NEXTAUTH_SECRET" --app "$APP_NAME"
heroku config:set NEXTAUTH_URL="https://$APP_NAME.herokuapp.com" --app "$APP_NAME"

# Encryption Keys
heroku config:set NEXT_PRIVATE_ENCRYPTION_KEY="$ENCRYPTION_KEY" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY="$SECONDARY_KEY" --app "$APP_NAME"

# Application URLs
heroku config:set NEXT_PUBLIC_WEBAPP_URL="https://$APP_NAME.herokuapp.com" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_INTERNAL_WEBAPP_URL="https://$APP_NAME.herokuapp.com" --app "$APP_NAME"

# Document upload limits
heroku config:set NEXT_PUBLIC_DOCUMENT_SIZE_UPLOAD_LIMIT="10" --app "$APP_NAME"

echo -e "${GREEN}✅ Environment variables set.${NC}"

# Ask for SMTP configuration
echo -e "${YELLOW}📧 SMTP Configuration${NC}"
read -p "Enter SMTP host: " SMTP_HOST
read -p "Enter SMTP port (default: 587): " SMTP_PORT
SMTP_PORT=${SMTP_PORT:-587}
read -p "Enter SMTP username: " SMTP_USERNAME
read -s -p "Enter SMTP password: " SMTP_PASSWORD
echo
read -p "Enter from email address: " FROM_EMAIL

# Set SMTP configuration
heroku config:set NEXT_PRIVATE_SMTP_TRANSPORT="smtp-auth" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_SMTP_HOST="$SMTP_HOST" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_SMTP_PORT="$SMTP_PORT" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_SMTP_USERNAME="$SMTP_USERNAME" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_SMTP_PASSWORD="$SMTP_PASSWORD" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_SMTP_FROM_NAME="Documenso" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_SMTP_FROM_ADDRESS="$FROM_EMAIL" --app "$APP_NAME"

# Ask for S3 configuration
echo -e "${YELLOW}🗄️  S3 Configuration${NC}"
read -p "Enter S3 endpoint (e.g., https://s3.amazonaws.com): " S3_ENDPOINT
read -p "Enter S3 region (e.g., us-east-1): " S3_REGION
read -p "Enter S3 bucket name: " S3_BUCKET
read -p "Enter S3 access key ID: " S3_ACCESS_KEY
read -s -p "Enter S3 secret access key: " S3_SECRET_KEY
echo

# Set S3 configuration
heroku config:set NEXT_PUBLIC_UPLOAD_TRANSPORT="s3" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_UPLOAD_ENDPOINT="$S3_ENDPOINT" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_UPLOAD_REGION="$S3_REGION" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_UPLOAD_BUCKET="$S3_BUCKET" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_UPLOAD_ACCESS_KEY_ID="$S3_ACCESS_KEY" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_UPLOAD_SECRET_ACCESS_KEY="$S3_SECRET_KEY" --app "$APP_NAME"

# Document signing configuration
echo -e "${YELLOW}📜 Document Signing Configuration${NC}"
read -s -p "Enter signing passphrase: " SIGNING_PASSPHRASE
echo

heroku config:set NEXT_PRIVATE_SIGNING_TRANSPORT="local" --app "$APP_NAME"
heroku config:set NEXT_PRIVATE_SIGNING_PASSPHRASE="$SIGNING_PASSPHRASE" --app "$APP_NAME"

echo -e "${GREEN}✅ Configuration complete.${NC}"

# Deploy the application
echo -e "${YELLOW}🚀 Deploying to Heroku...${NC}"

# Login to Heroku Container Registry
heroku container:login

# Build and push the image
echo -e "${YELLOW}📦 Building and pushing Docker image...${NC}"
heroku container:push web --app "$APP_NAME"

# Release the app
echo -e "${YELLOW}🎯 Releasing the app...${NC}"
heroku container:release web --app "$APP_NAME"

# Run database migrations
echo -e "${YELLOW}🗄️  Running database migrations...${NC}"
heroku run npm run prisma:migrate-deploy --app "$APP_NAME"

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${GREEN}🌐 Your app is available at: https://$APP_NAME.herokuapp.com${NC}"

# Open the app
read -p "Do you want to open the app in your browser? (y/n): " OPEN_APP
if [[ $OPEN_APP =~ ^[Yy]$ ]]; then
    heroku open --app "$APP_NAME"
fi

echo -e "${GREEN}🎉 Deployment successful!${NC}"
