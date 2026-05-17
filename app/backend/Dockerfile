FROM node:22-alpine

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

COPY package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node . .

EXPOSE 5000

USER node

CMD ["node", "server.js"]
