FROM node:26-slim
ENV NODE_ENV=production GRAPHILE_ENV=production
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY graphile.config.mjs server.mjs ./
EXPOSE 3108
CMD ["node", "server.mjs"]
