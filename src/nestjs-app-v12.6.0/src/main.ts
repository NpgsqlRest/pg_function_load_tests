import cluster from 'node:cluster';
import os from 'node:os';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';

// Workers = CPU cores so the single-threaded event loop can use the whole machine,
// matching natively multi-threaded runtimes (Go, Rust, .NET, JVM). Same as the Express and Fastify services.
const WORKERS = parseInt(process.env.WORKERS || '') || os.availableParallelism();

async function bootstrap() {
    // The default platform (Express), no request logging.
    const app = await NestFactory.create(AppModule, { logger: false });
    await app.listen(3106, '0.0.0.0');
}

if (cluster.isPrimary) {
    for (let i = 0; i < WORKERS; i++) {
        cluster.fork();
    }
    cluster.on('exit', () => cluster.fork());
} else {
    bootstrap();
}
