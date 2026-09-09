FROM node:26.8.1-bookworm-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json main.ts ./
RUN npm run build && npm prune --omit=dev
FROM node:26.8.1-bookworm-slim
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
EXPOSE 8000
CMD ["node", "dist/main.js"]
