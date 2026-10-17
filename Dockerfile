FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=amd64" -o /usr/bin/caddy && chmod +x /usr/bin/caddy

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
RUN npm install -g @deepseek-ai/dsh

RUN mkdir -p /etc/caddy && echo '{\n\
    admin off\n\
    auto_https off\n\
}\n\
:10000 {\n\
    basic_auth {\n\
        admin $$2a$$14$$REPLACE_WITH_A_REAL_BCRYPT_HASH\n\
    }\n\
    reverse_proxy 127.0.0.1:3080 {\n\
        header_up Host 127.0.0.1:3080\n\
        header_up Origin http://127.0.0.1:3080\n\
    }\n\
}' > /etc/caddy/Caddyfile

RUN echo '#!/bin/sh\n\
dsh web --host 127.0.0.1 --port 3080 --no-open &\n\
DSH_PID=$!\n\
caddy run --config /etc/caddy/Caddyfile &\n\
CADDY_PID=$!\n\
wait\n' > /start.sh && chmod +x /start.sh

ENV PORT=10000
EXPOSE 10000
CMD ["/start.sh"]
