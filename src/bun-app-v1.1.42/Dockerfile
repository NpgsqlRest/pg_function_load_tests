FROM oven/bun:1.1.42

WORKDIR /app
COPY package.json ./
RUN bun install --production
COPY . .

EXPOSE 3104

CMD ["bun", "run", "app.ts"]
