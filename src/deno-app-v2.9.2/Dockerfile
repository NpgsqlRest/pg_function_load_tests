FROM denoland/deno:2.9.2

WORKDIR /app
COPY app.ts .
RUN deno cache app.ts

EXPOSE 3105

CMD ["deno", "run", "--unstable-net", "--allow-net", "--allow-env", "--allow-read", "--allow-sys", "--allow-run", "app.ts"]
