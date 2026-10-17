# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

# System dependencies install karein
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Caddy download aur install karein
RUN curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=amd64" -o /usr/bin/caddy && chmod +x /usr/bin/caddy

# Corepack enable karein taaki pnpm ka error na aaye
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# DSH install karein
RUN npm install -g @deepseek-ai/dsh

# Caddyfile banayein (Yahan se header_up lines hata di gayi hain taaki cookie issue solve ho)
RUN mkdir -p /etc/caddy && cat <<'EOF' > /etc/caddy/Caddyfile
{
    admin off
    auto_https off
}
:10000 {
    basic_auth {
        admin $2a$12$zFqAjpvYav/YqyRClNVGyeGVAafBVDmx0TFY7HiKiGcrVwwxeshqu
    }
    reverse_proxy 127.0.0.1:3080
}
EOF

# Start script banayein (Trusted host add kar diya gaya hai)
RUN cat <<'EOF' > /start.sh
#!/bin/sh

# Plugin install karein
dsh plugin --profile web add dsh-remote-trust || true

# DSH web server start karein --trusted-host ke saath
dsh web --host 127.0.0.1 --port 3080 --no-open --trusted-host dsh-render-deploy.onrender.com &
DSH_PID=$!

# Caddy start karein
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!

wait
EOF

RUN chmod +x /start.sh

ENV PORT=10000
EXPOSE 10000
CMD ["/start.sh"]
