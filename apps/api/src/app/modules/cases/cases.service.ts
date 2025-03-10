import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Case, Course, Team, CaseEvent, User } from '../../models';
import { CreateCaseDto } from './dto/create-case.dto';
import { UpdateCaseDto } from './dto/update-case.dto';

@Injectable()
export class CasesService {
  constructor(
    @InjectModel(Case)
    private caseModel: typeof Case,
    @InjectModel(Course)
    private courseModel: typeof Course,
  ) {}

  async findAll(): Promise<Case[]> {
    return this.caseModel.findAll({
      include: [
        {
          model: Course,
          attributes: ['id', 'title', 'code'],
          include: [
            {
              model: User,
              as: 'professor',
              attributes: ['id', 'firstName', 'lastName', 'email'],
            },
          ],
        },
      ],
    });
  }

  async findByCourse(courseId: number): Promise<Case[]> {
    return this.caseModel.findAll({
      where: { courseId },
      include: [
        {
          model: Course,
          attributes: ['id', 'title', 'code'],
        },
      ],
    });
  }

  async findOne(id: number): Promise<Case> {
    const legalCase = await this.caseModel.findByPk(id, {
      include: [
        {
          model: Course,
          attributes: ['id', 'title', 'code'],
          include: [
            {
              model: User,
              as: 'professor',
              attributes: ['id', 'firstName', 'lastName', 'email'],
            },
          ],
        },
        {
          model: Team,
          attributes: ['id', 'name', 'role'],
        },
        {
          model: CaseEvent,
          attributes: [
            'id',
            'title',
            'eventType',
            'scheduledDate',
            'isVisible',
          ],
        },
      ],
    });

    if (!legalCase) {
      throw new NotFoundException(`Case with ID ${id} not found`);
    }

    return legalCase;
  }

  async create(createCaseDto: CreateCaseDto): Promise<Case> {
    const newCase = this.caseModel.build({
      ...createCaseDto,
    } as Partial<Case>);
    await newCase.save();
    return this.findOne(newCase.id);
  }

  async update(id: number, updateCaseDto: UpdateCaseDto): Promise<Case> {
    const legalCase = await this.findOne(id);
    await legalCase.update({
      ...updateCaseDto,
    } as Partial<Case>);
    return this.findOne(id);
  }

  async remove(id: number): Promise<void> {
    const legalCase = await this.findOne(id);
    await legalCase.destroy();
  }
}
