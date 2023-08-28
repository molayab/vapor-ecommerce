# ================================
# Build React public app with vite
# ================================
FROM node:alpine as react-build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY ./package*.json ./
RUN npm install --force

# Copy all files
COPY . .

# Build app
RUN npm run build

# Copy built React app
FROM nginx:alpine
COPY --from=react-build --chown=nginx:nginx /app/dist /usr/share/nginx/html/vapor