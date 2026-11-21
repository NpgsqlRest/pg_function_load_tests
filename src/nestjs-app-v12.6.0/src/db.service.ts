import os from 'node:os';
import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Pool } from 'pg';

const WORKERS = parseInt(process.env.WORKERS || '') || os.availableParallelism();

@Injectable()
export class DbService implements OnModuleDestroy {
    // The pool is per cluster worker; workers x max ~= 100 in total, to match the single-pool services.
    private readonly pool = new Pool({
        user: process.env.DB_USER,
        host: process.env.DB_HOST,
        database: process.env.DB_NAME,
        password: process.env.DB_PASSWORD,
        port: 5432,
        max: Math.max(2, Math.floor(100 / WORKERS)),
    });

    async query(text: string, values: unknown[] = []): Promise<any[]> {
        const result = await this.pool.query(text, values);
        return result.rows;
    }

    async onModuleDestroy() {
        await this.pool.end();
    }
}
