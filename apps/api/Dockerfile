FROM node:22.14.0-slim AS base

# Install postgresql-client for debugging
RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  curl \
  dumb-init \
  postgresql-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

FROM base AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts && \
  npm cache clean --force

COPY . .
RUN npx nx build api

# # Remove dev dependencies
# RUN npm prune --production


FROM base

WORKDIR /app

COPY --from=builder /app/dist/apps/api .
COPY --from=builder /app/node_modules ./node_modules

# # Create directory structure for migrations
# RUN mkdir -p config migrations

# Copy migrations and config with correct paths
COPY --from=builder /app/apps/api/src/assets/migrations/*.* ./migrations/
COPY --from=builder /app/apps/api/src/app/config/sequelize-cli.config.js ./config/

# Create a startup script
COPY --from=builder /app/apps/api/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

EXPOSE 3333

# Use the entrypoint script instead of directly running the app
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["./entrypoint.sh"]