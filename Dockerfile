# ... (system deps, caddy install, corepack enable — same as before)

WORKDIR /app
RUN npm install -g @deepseek-ai/dsh

# ❌ Remove this line: RUN dsh plugin --profile web add dsh-remote-trust

# Caddyfile (same as before)

RUN cat <<'EOF' > /start.sh
#!/bin/sh

# Install plugin at runtime
dsh plugin --profile web add dsh-remote-trust --registry https://registry.npmjs.org || true

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
