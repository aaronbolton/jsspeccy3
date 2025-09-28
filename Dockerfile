# Use Node.js 18 LTS as base image (compatible with the project)
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++

# Copy package files
COPY package*.json ./

# Install npm dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Install build dependencies
RUN npm install --save-dev assemblyscript@^0.19.6 webpack@^5.44.0 webpack-cli@^4.7.2 svg-inline-loader@^0.8.2 npm-watch@^0.10.0

# Copy source code
COPY . .

# Rename webpack config to .cjs for CommonJS compatibility
RUN mv webpack.config.js webpack.config.cjs

# Update package.json to use .cjs extension
RUN sed -i 's/webpack.config.js/webpack.config.cjs/g' package.json

# Build the project
RUN npm run build

# Create a simple server script for production
RUN cat > production-server.js << 'EOF'
import { createServer } from 'http';
import { readFileSync } from 'fs';
import { join, extname } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 8000;

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.wasm': 'application/wasm',
  '.css': 'text/css',
  '.json': 'application/json',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.rom': 'application/octet-stream',
  '.szx': 'application/octet-stream',
  '.tap': 'application/octet-stream',
  '.tzx': 'application/octet-stream',
  '.z80': 'application/octet-stream',
  '.sna': 'application/octet-stream'
};

createServer((req, res) => {
  let filePath = join(__dirname, 'dist', req.url === '/' ? 'index.html' : req.url);
  filePath = filePath.split('?')[0];
  const ext = extname(filePath).toLowerCase();
  
  try {
    const data = readFileSync(filePath);
    const mimeType = mimeTypes[ext] || 'text/plain';
    
    res.writeHead(200, { 
      'Content-Type': mimeType,
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cache-Control': 'public, max-age=31536000'
    });
    res.end(data);
  } catch (err) {
    res.writeHead(404, { 'Content-Type': 'text/html' });
    res.end('<h1>404 - Not Found</h1>');
  }
}).listen(PORT, '0.0.0.0', () => {
  console.log(`JSSpeccy3 server running on port ${PORT}`);
});
EOF

# Remove development dependencies and source files to reduce image size
RUN npm prune --production && \
    rm -rf \
    node_modules/.cache \
    generator \
    runtime \
    build \
    test \
    webpack.config.js \
    tsconfig.json \
    asconfig.json \
    .git

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/ || exit 1

# Start the server
CMD ["node", "production-server.js"]