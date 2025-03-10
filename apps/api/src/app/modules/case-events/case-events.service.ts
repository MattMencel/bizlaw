import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { CaseEvent, Case } from '../../models';
import { CreateCaseEventDto } from './dto/create-case-event.dto';
import { UpdateCaseEventDto } from './dto/update-case-event.dto';
import { WhereOptions } from 'sequelize';

@Injectable()
export class CaseEventsService {
  constructor(
    @InjectModel(CaseEvent)
    private caseEventModel: typeof CaseEvent,
    @InjectModel(Case)
    private caseModel: typeof Case,
  ) {}

  async findAll(): Promise<CaseEvent[]> {
    return this.caseEventModel.findAll({
      include: [{ model: Case, attributes: ['id', 'title'] }],
    });
  }

  async findByCaseId(
    caseId: number,
    includeInvisible = false,
  ): Promise<CaseEvent[]> {
    // Using a proper type for where conditions
    const where: WhereOptions<CaseEvent> = { caseId };

    if (!includeInvisible) {
      where.isVisible = true;
    }

    return this.caseEventModel.findAll({
      where,
      order: [['scheduledDate', 'ASC']],
    });
  }

  async findOne(id: number): Promise<CaseEvent> {
    const caseEvent = await this.caseEventModel.findByPk(id, {
      include: [{ model: Case, attributes: ['id', 'title'] }],
    });

    if (!caseEvent) {
      throw new NotFoundException(`Case event with ID ${id} not found`);
    }

    return caseEvent;
  }

  async create(createCaseEventDto: CreateCaseEventDto): Promise<CaseEvent> {
    // Verify case exists
    const caseExists = await this.caseModel.findByPk(createCaseEventDto.caseId);
    if (!caseExists) {
      throw new NotFoundException(
        `Case with ID ${createCaseEventDto.caseId} not found`,
      );
    }

    // Create event using build() and save() instead of create()
    // Using proper type casting instead of 'any'
    const caseEvent = this.caseEventModel.build(
      createCaseEventDto as Partial<CaseEvent>,
    );
    await caseEvent.save();
    return this.findOne(caseEvent.id);
  }

  async update(
    id: number,
    updateCaseEventDto: UpdateCaseEventDto,
  ): Promise<CaseEvent> {
    const caseEvent = await this.findOne(id);
    await caseEvent.update(updateCaseEventDto as Partial<CaseEvent>);
    return this.findOne(id);
  }

  async remove(id: number): Promise<void> {
    const caseEvent = await this.findOne(id);
    await caseEvent.destroy();
  }

  async toggleVisibility(id: number): Promise<CaseEvent> {
    const caseEvent = await this.findOne(id);
    await caseEvent.update({
      isVisible: !caseEvent.isVisible,
    } as Partial<CaseEvent>);
    return this.findOne(id);
  }
}
