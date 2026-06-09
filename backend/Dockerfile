# ============================================================
# 智能用药App - 后端API Dockerfile
# ============================================================

# ---- Build Stage ----
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --only=production

# ---- Production Stage ----
FROM node:22-alpine

RUN apk add --no-cache tini curl

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Copy production dependencies
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Copy application code
COPY src ./src
COPY migrations ./migrations

# Create logs directory
RUN mkdir -p logs && chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "src/server.js"]
