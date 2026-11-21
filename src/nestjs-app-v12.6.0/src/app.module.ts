import { Module } from '@nestjs/common';
import { DbService } from './db.service.js';
import { PerfController } from './perf.controller.js';

@Module({
    controllers: [PerfController],
    providers: [DbService],
})
export class AppModule {}
