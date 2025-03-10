import {
  Controller,
  Get,
  Post,
  Body,
  Put,
  Param,
  Delete,
  UseGuards,
  Query,
  Patch,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CaseEventsService } from './case-events.service';
import { CreateCaseEventDto } from './dto/create-case-event.dto';
import { UpdateCaseEventDto } from './dto/update-case-event.dto';

@Controller('case-events')
@UseGuards(JwtAuthGuard)
export class CaseEventsController {
  constructor(private readonly caseEventsService: CaseEventsService) {}

  @Get()
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  findAll() {
    return this.caseEventsService.findAll();
  }

  @Get('case/:caseId')
  findByCaseId(
    @Param('caseId') caseId: number,
    @Query('includeInvisible') includeInvisible: boolean,
  ) {
    return this.caseEventsService.findByCaseId(caseId, includeInvisible);
  }

  @Get(':id')
  findOne(@Param('id') id: number) {
    return this.caseEventsService.findOne(id);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  create(@Body() createCaseEventDto: CreateCaseEventDto) {
    return this.caseEventsService.create(createCaseEventDto);
  }

  @Put(':id')
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  update(
    @Param('id') id: number,
    @Body() updateCaseEventDto: UpdateCaseEventDto,
  ) {
    return this.caseEventsService.update(id, updateCaseEventDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  remove(@Param('id') id: number) {
    return this.caseEventsService.remove(id);
  }

  @Patch(':id/toggle-visibility')
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  toggleVisibility(@Param('id') id: number) {
    return this.caseEventsService.toggleVisibility(id);
  }
}
