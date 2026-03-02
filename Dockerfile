# =========================
# Stage 1 - Build
# =========================
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

# Require build argument
ARG VITE_BACKEND_API_URL
RUN test -n "$VITE_BACKEND_API_URL"

ENV VITE_BACKEND_API_URL=$VITE_BACKEND_API_URL

RUN npm run build


# =========================
# Stage 2 - Nginx
# =========================
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Create SPA config directly from Dockerfile
RUN printf 'server {\n\
    listen 80;\n\
    server_name localhost;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

# Copy build result
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]