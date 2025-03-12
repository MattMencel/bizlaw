FROM node:22.14.0-slim AS base

# Install packages
RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  curl \
  dumb-init \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

FROM base AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts

COPY . .
# RUN npx nx build web

WORKDIR /app/apps/web
RUN npx next build && \
  npm cache clean --force

RUN npm prune --production

FROM base

WORKDIR /app

# Copy only the necessary files and directories
COPY --from=builder /app/apps/web/.next ./.next
# COPY --from=builder /app/apps/web/public ./public
COPY --from=builder /app/apps/web/package.json ./package.json
COPY --from=builder /app/apps/web/next.config.js ./next.config.js
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/web/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

EXPOSE 3000

# Use entrypoint script
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["./entrypoint.sh"]
