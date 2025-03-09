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
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CasesService } from './cases.service';
import { CreateCaseDto } from './dto/create-case.dto';
import { UpdateCaseDto } from './dto/update-case.dto';

@Controller('cases')
@UseGuards(JwtAuthGuard)
export class CasesController {
  constructor(private readonly casesService: CasesService) {}

  @Get()
  findAll() {
    return this.casesService.findAll();
  }

  @Get('course/:courseId')
  findByCourse(@Param('courseId') courseId: number) {
    return this.casesService.findByCourse(courseId);
  }

  @Get(':id')
  findOne(@Param('id') id: number) {
    return this.casesService.findOne(id);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  create(@Body() createCaseDto: CreateCaseDto) {
    return this.casesService.create(createCaseDto);
  }

  @Put(':id')
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  update(@Param('id') id: number, @Body() updateCaseDto: UpdateCaseDto) {
    return this.casesService.update(id, updateCaseDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('professor', 'admin')
  remove(@Param('id') id: number) {
    return this.casesService.remove(id);
  }
}
