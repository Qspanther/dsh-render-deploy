FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=amd64" -o /usr/bin/caddy && chmod +x /usr/bin/caddy

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
RUN npm install -g @deepseek-ai/dsh

RUN mkdir -p /etc/caddy && cat <<'EOF' > /etc/caddy/Caddyfile
{
    admin off
    auto_https off
}
:10000 {
    basic_auth {
        admin $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
    }
    reverse_proxy 127.0.0.1:3080 {
        header_up Host 127.0.0.1:3080
        header_up Origin http://127.0.0.1:3080
    }
}
EOF

RUN echo '#!/bin/sh
dsh web --host 127.0.0.1 --port 3080 --no-open &
DSH_PID=$!
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!
wait
' > /start.sh && chmod +x /start.sh

ENV PORT=10000
EXPOSE 10000
CMD ["/start.sh"]
