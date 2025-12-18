# Serve with Nginx (Pre-built assets from Host)
FROM nginx:alpine

# Copy built assets from host directory
COPY build/web /usr/share/nginx/html

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
