import { createServer } from 'http';
import { readFileSync } from 'fs';
import { join, extname } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

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
  
  // Remove query parameters
  filePath = filePath.split('?')[0];
  
  const ext = extname(filePath).toLowerCase();
  
  try {
    const data = readFileSync(filePath);
    const mimeType = mimeTypes[ext] || 'text/plain';
    
    res.writeHead(200, { 
      'Content-Type': mimeType,
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin'
    });
    res.end(data);
    
    console.log(`Served: ${req.url} (${mimeType})`);
  } catch (err) {
    console.error(`Error serving ${req.url}:`, err.message);
    res.writeHead(404, { 'Content-Type': 'text/html' });
    res.end(`
      <!DOCTYPE html>
      <html>
        <head><title>404 - Not Found</title></head>
        <body>
          <h1>404 - File Not Found</h1>
          <p>The requested file <code>${req.url}</code> was not found.</p>
          <p><a href="/">Go back to home</a></p>
        </body>
      </html>
    `);
  }
}).listen(8000, () => {
  console.log('JSSpeccy3 server running at http://localhost:8000');
  console.log('Make sure you have built the project first with: npm run build');
});