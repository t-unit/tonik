FROM node:26.8.1-bookworm-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY server.js .
EXPOSE 8000
CMD ["node", "server.js"]
