FROM node:22.14.0-slim AS base

# Install packages
RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  curl=7.88.1-10+deb12u12 \
  dumb-init=1.2.5-2 \
  postgresql-client-15=15.12-0+deb12u2 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

FROM base AS builder

WORKDIR /app

COPY package*.json ./
COPY apps/bizlaw/package.json ./apps/bizlaw/

# Install dependencies
RUN npm ci --ignore-scripts

COPY . .

# Build the bizlaw app
RUN npx nx build bizlaw

FROM base

WORKDIR /app

# Copy the built bizlaw app
COPY --from=builder /app/dist/apps/bizlaw/ .
COPY --from=builder /app/node_modules ./node_modules
# Copy migration files
COPY --from=builder /app/drizzle ./drizzle

# Copy entrypoint script and make it executable
COPY --from=builder /app/apps/bizlaw/entrypoint.sh ./
RUN chmod +x ./entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--", "./entrypoint.sh"]
CMD ["node", "server.js"]
