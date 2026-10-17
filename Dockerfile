# --- Apna Username aur Password yahan daalein ---
$username = "admin"
$password = "Panther#123"

# Password ka bcrypt hash generate karein
$hash = node -e "const bcrypt = require('bcryptjs'); console.log(bcrypt.hashSync('$password', 10))"

# Dockerfile ka saaf content (sirf Docker instructions)
$dockerfileContent = @"
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

# File ko BOM ke bina save karein (sabse zaroori step)
[System.IO.File]::WriteAllText("$PWD\Dockerfile", $dockerfileContent)

# GitHub par push karein
git add Dockerfile
git commit -m "Fix: Correct Dockerfile syntax and remove BOM"
git push origin main

Write-Host "Done! Ab Render Dashboard mein Manual Deploy karein." -ForegroundColor Green