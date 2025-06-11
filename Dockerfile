FROM node:22-alpine3.20

# Install system dependencies
RUN apk add --no-cache openssl libc6-compat jq make cmake g++ bash

# Set working directory
WORKDIR /app

# Copy everything
COPY . .

# Debug: List what was copied
RUN ls -la

# Check if key files exist
RUN test -f package.json && echo "package.json found" || echo "package.json NOT found"

# Install dependencies
RUN npm ci

# Set environment variables
ENV HUSKY=0
ENV DOCKER_OUTPUT=1
ENV NEXT_TELEMETRY_DISABLED=1

# Build the application
RUN npm run build

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Change ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Set working directory to the remix app
WORKDIR /app/apps/remix

# Copy start script
COPY --chown=nodejs:nodejs docker/start.sh ./start.sh

# Make start script executable
RUN chmod +x start.sh

# Start the application
CMD ["./start.sh"] 