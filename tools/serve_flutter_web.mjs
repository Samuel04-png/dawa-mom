import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve, sep } from 'node:path';

const root = resolve(process.argv[2] ?? 'build/web');
const port = Number.parseInt(process.env.PORT ?? '8080', 10);

const contentTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

if (!existsSync(root) || !statSync(root).isDirectory()) {
  console.error(`Static root not found: ${root}`);
  console.error('Build the web app first, or pass a directory: node tools/serve_flutter_web.mjs build/web');
  process.exit(1);
}

function resolveRequestPath(urlPath) {
  const decodedPath = decodeURIComponent(urlPath.split('?')[0] || '/');
  const relativePath = normalize(decodedPath).replace(/^([/\\])+/, '');
  const filePath = resolve(join(root, relativePath));

  if (filePath !== root && !filePath.startsWith(`${root}${sep}`)) {
    return null;
  }

  if (existsSync(filePath) && statSync(filePath).isFile()) {
    return filePath;
  }

  const indexPath = join(root, 'index.html');
  return existsSync(indexPath) ? indexPath : null;
}

const server = createServer((request, response) => {
  const filePath = resolveRequestPath(request.url ?? '/');

  if (!filePath) {
    response.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
    response.end('Not found');
    return;
  }

  response.writeHead(200, {
    'cache-control': filePath.endsWith('index.html') ? 'no-cache' : 'public, max-age=3600',
    'content-type': contentTypes[extname(filePath)] ?? 'application/octet-stream',
  });
  createReadStream(filePath).pipe(response);
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Serving ${root} at http://127.0.0.1:${port}`);
});
