FROM node:26-slim

ENV NODE_ENV=production

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .

EXPOSE 3102

CMD ["node", "app.js"]
