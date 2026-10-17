FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y git curl caddy && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
RUN npm install -g @deepseek-ai/dsh
RUN echo ':10000 {\n basic_auth {\n  admin $$2a$$14$$REPLACE_WITH_A_REAL_BCRYPT_HASH\n }\n reverse_proxy 127.0.0.1:3080 {\n  header_up Host 127.0.0.1:3080\n  header_up Origin http://127.0.0.1:3080\n }\n}' > /etc/caddy/Caddyfile
RUN echo '#!/bin/sh\n dsh web --host 127.0.0.1 --port 3080 --no-open &\n DSH_PID=$!\n caddy run --config /etc/caddy/Caddyfile &\n CADDY_PID=$!\n wait -n $DSH_PID $CADDY_PID\n' > /start.sh && chmod +x /start.sh
ENV PORT=10000
EXPOSE 10000
CMD ["/start.sh"]
