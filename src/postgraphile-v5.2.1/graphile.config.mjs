import os from 'node:os';
import { PostGraphileAmberPreset } from 'postgraphile/presets/amber';
import { makePgService } from 'postgraphile/adaptors/pg';

const WORKERS = parseInt(process.env.WORKERS || '') || os.availableParallelism();

// PostGraphile as it comes: the standard preset, the public schema, nothing tuned or removed.
// No watch mode and no GraphiQL: this is the production shape.
export default {
    extends: [PostGraphileAmberPreset],
    pgServices: [
        makePgService({
            connectionString: `postgres://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:5432/${process.env.DB_NAME}`,
            schemas: ['public'],
            // The pool is per cluster worker; workers x max ~= 100 in total, to match the single-pool services.
            poolConfig: { max: Math.max(2, Math.floor(100 / WORKERS)) },
        }),
    ],
    grafserv: { port: 3108, host: '0.0.0.0', graphiql: false, watch: false },
    grafast: { explain: false },
};
