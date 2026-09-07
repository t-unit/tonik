FROM node:22.19.0-bookworm-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY server.js .
EXPOSE 8000
CMD ["node", "server.js"]
