FROM node:24-slim

ENV NODE_ENV=production

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .

EXPOSE 3102

CMD ["node", "app.js"]
