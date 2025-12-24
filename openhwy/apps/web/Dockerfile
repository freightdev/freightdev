FROM node:20-alpine AS builder
WORKDIR /app
ARG ENV_FILE=.env
COPY package*.json ./
RUN npm install
COPY . .
COPY ${ENV_FILE} /app/.env
RUN npm run build

FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 4173
CMD ["nginx", "-g", "daemon off;"]
