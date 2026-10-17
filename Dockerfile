# --- Yahan apna Username aur Password daalein ---
$username = "admin"
$password = "Panther#123"

# Password ka bcrypt hash generate karein (Node.js ke through)
Write-Host "Password hash banaya ja raha hai..." -ForegroundColor Cyan
$hash = node -e "const bcrypt = require('bcryptjs'); console.log(bcrypt.hashSync('$password', 10))"

# Dockerfile ka naya content
$dockerfile = @"
FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=amd64" -o /usr/bin/caddy && chmod +x /usr/bin/caddy

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
RUN npm install -g @deepseek-ai/dsh

RUN mkdir -p /etc/caddy && echo '{
    admin off
    auto_https off
}
:10000 {
    basic_auth {
        $username $hash
    }
    reverse_proxy 127.0.0.1:3080 {
        header_up Host 127.0.0.1:3080
        header_up Origin http://127.0.0.1:3080
    }
}' > /etc/caddy/Caddyfile

RUN echo '#!/bin/sh
dsh web --host 127.0.0.1 --port 3080 --no-open &
DSH_PID=`$!
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=`$!
wait
' > /start.sh && chmod +x /start.sh

ENV PORT=10000
EXPOSE 10000
CMD ["/start.sh"]
"@

# Dockerfile save karein
$dockerfile | Out-File -Encoding utf8 -FilePath "Dockerfile"

# GitHub par push karein
git add Dockerfile
git commit -m "Fix: Add real bcrypt hash for Caddy basic auth"
git push origin main

Write-Host "Done! Ab Render dashboard mein Manual Deploy karein." -ForegroundColor Green
Write-Host "Aapka Username: $username" -ForegroundColor Yellow