import cluster from 'node:cluster';
import os from 'node:os';
import { createServer } from 'node:http';
import { postgraphile } from 'postgraphile';
import { grafserv } from 'postgraphile/grafserv/node';
import preset from './graphile.config.mjs';

// Workers = CPU cores so the single-threaded event loop can use the whole machine,
// matching natively multi-threaded runtimes. Same as the other Node services.
const WORKERS = parseInt(process.env.WORKERS || '') || os.availableParallelism();

if (cluster.isPrimary) {
    for (let i = 0; i < WORKERS; i++) {
        cluster.fork();
    }
    cluster.on('exit', () => cluster.fork());
} else {
    const pgl = postgraphile(preset);
    const serv = pgl.createServ(grafserv);
    const server = createServer();
    server.on('error', (e) => console.error(e));
    serv.addTo(server).catch((e) => {
        console.error(e);
        process.exit(1);
    });
    server.listen(preset.grafserv.port, preset.grafserv.host);
}
