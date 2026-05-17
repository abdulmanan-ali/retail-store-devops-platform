FROM node:20-alpine AS build

WORKDIR /usr/src/app

COPY --chown=node:node src/checkout/package*.json ./

RUN npm install

COPY --chown=node:node src/checkout/ .
RUN npm run build

FROM node:20-alpine

LABEL org.opencontainers.image.title="retail-store-checkout" \
      org.opencontainers.image.description="Checkout service - NestJS/Redis" \
      org.opencontainers.image.source="https://github.com/abdulmanan-ali/retail-store-devops-platform"

COPY --chown=node:node --from=build /usr/src/app/dist ./dist
COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules

ENTRYPOINT [ "node", "dist/main.js" ]
