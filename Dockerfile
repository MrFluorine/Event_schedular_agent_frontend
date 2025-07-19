# Use Node.js 20 for building and serving the React app
FROM node:20-alpine as build

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Accept build arguments
ARG VITE_BACKEND_URL
ARG VITE_GOOGLE_CLIENT_ID  
ARG VITE_OAUTH_REDIRECT_URI

# Set environment variables for Vite build
ENV VITE_BACKEND_URL=$VITE_BACKEND_URL
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID
ENV VITE_OAUTH_REDIRECT_URI=$VITE_OAUTH_REDIRECT_URI

# Debug: Print environment variables during build
RUN echo "Building with Node.js version:" && node --version
RUN echo "Build-time VITE_BACKEND_URL: $VITE_BACKEND_URL"
RUN echo "Build-time VITE_GOOGLE_CLIENT_ID: ${VITE_GOOGLE_CLIENT_ID:0:20}..."
RUN echo "Build-time VITE_OAUTH_REDIRECT_URI: $VITE_OAUTH_REDIRECT_URI"

# Build the application
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Install gettext for envsubst (if needed for runtime substitution)
RUN apk add --no-cache gettext

# Copy built files from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]