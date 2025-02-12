# Base Bun image
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# Install dependencies
FROM base AS install
RUN mkdir -p /temp/dev

# Copy lockfile and package.json (to leverage Docker caching)
COPY package.json bun.lock /temp/dev/
COPY patches /temp/dev/patches

# Copy only necessary packages to install dependencies efficiently
COPY packages/backend /temp/dev/packages/backend
COPY packages/shared /temp/dev/packages/shared


# Install all dependencies for backend (including shared dependencies)
RUN cd /temp/dev && bun install --no-cache

# Debugging: Check installed node_modules
RUN ls -al /temp/dev/node_modules

# Create final production image
FROM base AS release

# Copy installed dependencies
COPY --from=install /temp/dev/node_modules /usr/src/app/node_modules
# COPY --from=install /temp/dev/.bun /usr/src/app/.bun

# Copy workspace files
COPY --from=install /temp/dev/bun.lock bun.lock
COPY --from=install /temp/dev/package.json package.json
COPY --from=install /temp/dev/patches /temp/dev/patches
COPY --from=install /temp/dev/packages/backend ./packages/backend
COPY --from=install /temp/dev/packages/shared ./packages/shared

# Set environment variables for Bun
ENV BUN_INSTALL="/usr/src/app/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"

# Use non-root user
USER bun

# Expose backend port
EXPOSE 8080/tcp

# Debugging: Keep container running to check files
# ENTRYPOINT ["sh", "-c", "ls -al /usr/src/app/node_modules && tail -f /dev/null"]

# Start backend service (Uncomment for production)
ENTRYPOINT ["bun", "run", "start:backend:run"]
