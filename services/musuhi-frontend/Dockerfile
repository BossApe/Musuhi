FROM node:20-alpine
WORKDIR /app
ARG VITE_API_BASE_URL=http://localhost:18080
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build
ARG PORT=3000
EXPOSE ${PORT}
ENV PORT=${PORT}
ENV NODE_ENV=production
CMD ["sh", "-c", "npm run preview -- --host 0.0.0.0 --port $PORT"]
