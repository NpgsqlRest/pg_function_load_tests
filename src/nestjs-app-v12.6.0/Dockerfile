FROM node:26-slim AS build
WORKDIR /build
# The project is the one "nest new" creates (its tsconfig, its build), so that it is built the way the
# framework's own tooling builds an application. Only the source files of this service replace the template's.
RUN npx -y @nestjs/cli@12.0.15 new app --skip-git --skip-install --package-manager npm
WORKDIR /build/app
RUN npm install \
    && npm install @nestjs/common@12.6.0 @nestjs/core@12.6.0 @nestjs/platform-express@12.6.0 pg@8.23.1 \
    && npm install --save-dev @types/pg
RUN rm -rf src test
COPY src ./src
RUN npm run build && npm prune --omit=dev

FROM node:26-slim
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /build/app/node_modules ./node_modules
COPY --from=build /build/app/dist ./dist
COPY --from=build /build/app/package.json ./package.json
EXPOSE 3106
CMD ["node", "dist/main.js"]
