FROM cirrusci/flutter:latest AS builder
WORKDIR /app
ARG ENV_FILE=.env
COPY pubspec.* ./
RUN flutter pub get
COPY . .
COPY ${ENV_FILE} /app/.env
RUN flutter config --enable-web
RUN flutter build web --release --dart-define=FLUTTER_API_BASE_URL=${FLUTTER_API_BASE_URL:-http://localhost:3000/api}

FROM nginx:stable-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 5200
CMD ["nginx", "-g", "daemon off;"]
