# 1. Apna username aur password yahan set karein
$user = "admin"
$pass = "Panther#123"

# 2. Password ka hash banayein
$hash = node -e "const bcrypt = require('bcryptjs'); console.log(bcrypt.hashSync('$pass', 10))"

# 3. Dockerfile ka saaf content taiyar karein (sirf Docker commands)
$content = @"
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
        $user $hash
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

# 4. Sabse zaroori step: File ko BOM ke bina (saaf UTF-8) save karein
[System.IO.File]::WriteAllText("$PWD\Dockerfile", $content, (New-Object System.Text.UTF8Encoding $False))

# 5. GitHub par push karein
git add Dockerfile
git commit -m "Fix: Clean Dockerfile content and encoding"
git push origin main