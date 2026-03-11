# Stage 1: Install dependencies (Debian/glibc so better-sqlite3 native bindings build and load)
FROM node:20-slim AS deps
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Stage 2: Build
FROM node:20-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN corepack enable pnpm && pnpm build

# Stage 3: Production
FROM node:20-slim AS runner
RUN apt-get update && apt-get install -y --no-install-recommends tini \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/dist/main.cjs ./main.cjs
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Create data directory for Actual's local SQLite cache
RUN mkdir -p /app/data

VOLUME /app/data

ENV ACTUAL_DATA_DIR=/app/data
ENV NODE_ENV=production

# Use tini as init process for proper signal handling in Docker
ENTRYPOINT ["/usr/bin/tini", "--", "node", "main.cjs"]
