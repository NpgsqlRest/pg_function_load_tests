import { Body, Controller, Get, HttpCode, Post, Query } from '@nestjs/common';
import { DbService } from './db.service.js';

type Q = Record<string, string>;

@Controller('api')
export class PerfController {
    constructor(private readonly db: DbService) {}

    @Get('perf-test')
    perfTest(@Query() q: Q) {
        return this.db.query(
            `SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                    numeric_val, real_val, double_val, bool_val, date_val, time_val,
                    timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                    int_array_val, text_array_val, nullable_text, nullable_int
             FROM public.perf_test($1, $2, $3, $4::bigint, $5::numeric, $6::real, $7::double precision, $8, $9::date, $10::timestamp, $11::timestamptz, $12::uuid, $13::json, $14::jsonb, $15::int[], $16::text[])`,
            [
                parseInt(q._records), q._text, parseInt(q._int), q._bigint, q._numeric, q._real, q._double,
                q._bool === 'true', q._date, q._timestamp, q._timestamptz, q._uuid, q._json, q._jsonb,
                q._int_array, q._text_array,
            ],
        );
    }

    @Get('perf-minimal')
    perfMinimal() {
        return this.db.query('SELECT status, ts FROM public.perf_minimal()');
    }

    @Post('perf-post')
    @HttpCode(200)
    perfPost(@Body() body: { _records?: number; _payload?: unknown }) {
        return this.db.query('SELECT row_num, echo, computed FROM public.perf_post($1, $2::jsonb)', [
            body._records ?? 10,
            JSON.stringify(body._payload ?? {}),
        ]);
    }

    @Get('perf-nested')
    perfNested(@Query() q: Q) {
        return this.db.query('SELECT row_num, nested FROM public.perf_nested($1, $2)', [
            parseInt(q._records || '100'),
            parseInt(q._depth || '3'),
        ]);
    }

    @Get('perf-large-payload')
    perfLargePayload(@Query() q: Q) {
        return this.db.query('SELECT data FROM public.perf_large_payload($1)', [parseInt(q._size_kb || '100')]);
    }

    @Get('perf-many-params')
    perfManyParams(@Query() q: Q) {
        return this.db.query(
            `SELECT param_count, checksum FROM public.perf_many_params(
                $1, $2::int, $3::bool, $4::numeric, $5,
                $6, $7::int, $8::bool, $9::numeric, $10,
                $11, $12::int, $13::bool, $14::numeric, $15,
                $16, $17::int, $18::bool, $19::numeric, $20
            )`,
            [
                q._p1, q._p2, q._p3 === 'true', q._p4, q._p5,
                q._p6, q._p7, q._p8 === 'true', q._p9, q._p10,
                q._p11, q._p12, q._p13 === 'true', q._p14, q._p15,
                q._p16, q._p17, q._p18 === 'true', q._p19, q._p20,
            ],
        );
    }

    @Get('perf-table-get')
    perfTableGet(@Query() q: Q) {
        return this.db.query(
            'SELECT id, name, category, price, active, created_at FROM public.perf_table_get($1)',
            [parseInt(q._id)],
        );
    }

    @Get('perf-table-list')
    perfTableList(@Query() q: Q) {
        return this.db.query(
            'SELECT id, name, category, price, active, created_at FROM public.perf_table_list($1, $2, $3)',
            [parseInt(q._category), parseInt(q._after_id), parseInt(q._limit)],
        );
    }

    @Post('perf-table-insert')
    @HttpCode(200)
    perfTableInsert(@Body() body: { _item_id: number; _quantity: number; _note: string }) {
        return this.db.query(
            'SELECT id, item_id, quantity, note, created_at FROM public.perf_table_insert($1, $2, $3)',
            [body._item_id, body._quantity, body._note],
        );
    }
}
