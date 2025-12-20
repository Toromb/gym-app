# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependency definitions
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build for web
# --release defaults to optimizing for speed and size
# --base-href / ensures routing works from root
RUN flutter clean
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:1.25-alpine

# Copy built assets from Stage 1
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
