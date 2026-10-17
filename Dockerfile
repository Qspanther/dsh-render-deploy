# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=amd64" -o /usr/bin/caddy && chmod +x /usr/bin/caddy

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
RUN npm install -g @deepseek-ai/dsh
RUN dsh plugin --profile web add dsh-remote-trust

RUN mkdir -p /etc/caddy && cat <<'EOF' > /etc/caddy/Caddyfile
{
    admin off
    auto_https off
}
:10000 {
    basic_auth {
        admin $2a$12$8uomYitbPdeVHrN0BF27UOR7VqqKZVM95BJDRsAgkim2bK9vBwyxW
    }
    reverse_proxy 127.0.0.1:3080 {
        header_up Host 127.0.0.1:3080
        header_up Origin http://127.0.0.1:3080
    }
}
EOF

RUN cat <<'EOF' > /start.sh
#!/bin/sh
dsh web --host 127.0.0.1 --port 3080 --no-open &
DSH_PID=$!
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!
wait
EOF
RUN chmod +x /start.sh

ENV PORT=10000
EXPOSE 10000
CMD ["/start.sh"]
