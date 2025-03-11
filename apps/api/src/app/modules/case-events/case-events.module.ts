import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { CaseEvent, Case } from '../../models';
import { CaseEventsService } from './case-events.service';
import { CaseEventsController } from './case-events.controller';
import { CommonModule } from '../common/common.module';

@Module({
  imports: [SequelizeModule.forFeature([CaseEvent, Case]), CommonModule],
  controllers: [CaseEventsController],
  providers: [CaseEventsService],
  exports: [CaseEventsService],
})
export class CaseEventsModule {}
