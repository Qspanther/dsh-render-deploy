# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

# System dependencies install karein
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Caddy download aur install karein
RUN curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=amd64" -o /usr/bin/caddy && chmod +x /usr/bin/caddy

# === YEH SABSE IMPORTANT FIX HAI ===
# Corepack ko enable karein taaki pnpm command pehle se ready ho
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# DSH install karein (ab pnpm ready hai, isliye error nahi aayega)
RUN npm install -g @deepseek-ai/dsh

# DSH plugin add karein
RUN dsh plugin --profile web add dsh-remote-trust

# Caddyfile banayein
RUN mkdir -p /etc/caddy && cat <<'EOF' > /etc/caddy/Caddyfile
{
    admin off
    auto_https off
}
:10000 {
    basic_auth {
        admin $2a$12$zFqAjpvYav/YqyRClNVGyeGVAafBVDmx0TFY7HiKiGcrVwwxeshqu
    }
    reverse_proxy 127.0.0.1:3080 {
        header_up Host 127.0.0.1:3080
        header_up Origin http://127.0.0.1:3080
    }
}
EOF

# Start script banayein
RUN cat <<'EOF' > /start.sh
#!/bin/sh

# DSH plugin enable karein (agar pehle se enabled hai to ignore karega)
dsh plugin --profile web enable dsh-remote-trust || true

# DSH web server background mein start karein
dsh web --host 127.0.0.1 --port 3080 --no-open &
DSH_PID=$!

# Caddy ko background mein start karein
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!

# Dono processes ke chalte rehne ka wait karein
wait
EOF

RUN chmod +x /start.sh

ENV PORT=10000
EXPOSE 10000
CMD ["/start.sh"]
