#!/bin/bash

set -e

echo "🚀 Setting up Documenso local development environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "✅ .env file created. Please edit it with your configuration."
else
    echo "✅ .env file already exists."
fi

# Generate secrets if they don't exist in .env
if ! grep -q "your-nextauth-secret-here" .env; then
    echo "🔐 Generating secrets..."

    # Generate NextAuth secret
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    sed -i.bak "s/your-nextauth-secret-here/$NEXTAUTH_SECRET/" .env

    # Generate encryption keys
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    sed -i.bak "s/your-encryption-key-here/$ENCRYPTION_KEY/" .env

    SECONDARY_KEY=$(openssl rand -base64 32)
    sed -i.bak "s/your-secondary-encryption-key-here/$SECONDARY_KEY/" .env

    echo "✅ Secrets generated and updated in .env file."
else
    echo "✅ Secrets already configured in .env file."
fi

# Start development services
echo "🐳 Starting development services..."
npm run dx:up

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Install dependencies and setup database
echo "📦 Installing dependencies and setting up database..."
npm run dx

echo "✅ Local development environment is ready!"
echo ""
echo "🎯 Next steps:"
echo "1. Edit .env file if needed"
echo "2. Run 'npm run dev' to start the application"
echo "3. Visit http://localhost:3000"
echo ""
echo "📧 Email testing available at: http://localhost:9000"
echo "🗄️  MinIO console available at: http://localhost:9001"
echo "📊 Database available at: localhost:54320"
