FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
RUN npm install -g @deepseek-ai/dsh
ENV PORT=10000
EXPOSE 10000
CMD ["dsh", "web", "--host", "0.0.0.0", "--port", "10000", "--no-open", "--trusted-host", "*.onrender.com"]
