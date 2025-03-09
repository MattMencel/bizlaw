import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { Case, Course, Team, CaseEvent, Document } from '../../models';
import { CasesService } from './cases.service';
import { CasesController } from './cases.controller';

@Module({
  imports: [
    SequelizeModule.forFeature([Case, Course, Team, CaseEvent, Document]),
  ],
  controllers: [CasesController],
  providers: [CasesService],
  exports: [CasesService],
})
export class CasesModule {}
