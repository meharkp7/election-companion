# backend/Dockerfile
FROM node:18-slim

# Create app directory
WORKDIR /src/app

# Install app dependencies
COPY package*.json ./
RUN npm install --production

# Bundle app source
COPY . .
ENV NODE_ENV=production
# Expose port (Cloud Run defaults to 8080)
ENV PORT=8080
EXPOSE 8080

# Run the app
CMD [ "node", "src/server.js" ]
