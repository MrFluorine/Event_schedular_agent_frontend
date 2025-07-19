# Use Node.js 20 for building and serving the React app
FROM node:20-alpine as build

WORKDIR /app

# Copy package.json first
COPY package.json ./

# Delete lock file and install fresh dependencies including terser
RUN rm -f package-lock.json && \
    npm install && \
    npm install --save-dev terser

# Copy rest of source code
COPY . .

# Accept build arguments with Cloud Build substitution variable names
ARG _VITE_BACKEND_URL
ARG _VITE_GOOGLE_CLIENT_ID  
ARG _VITE_OAUTH_REDIRECT_URI

# Set environment variables for Vite build
ENV VITE_BACKEND_URL=$_VITE_BACKEND_URL
ENV VITE_GOOGLE_CLIENT_ID=$_VITE_GOOGLE_CLIENT_ID
ENV VITE_OAUTH_REDIRECT_URI=$_VITE_OAUTH_REDIRECT_URI

# Debug: Print environment variables during build
RUN echo "Building with Node.js version:" && node --version
RUN echo "Build-time VITE_BACKEND_URL: '$VITE_BACKEND_URL'"
RUN echo "Build-time VITE_GOOGLE_CLIENT_ID: '${VITE_GOOGLE_CLIENT_ID:0:20}...'"
RUN echo "Build-time VITE_OAUTH_REDIRECT_URI: '$VITE_OAUTH_REDIRECT_URI'"

# Build the application
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Copy built files from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]