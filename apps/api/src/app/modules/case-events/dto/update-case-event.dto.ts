import { PartialType } from '@nestjs/mapped-types';
import { CreateCaseEventDto } from './create-case-event.dto';

export class UpdateCaseEventDto extends PartialType(CreateCaseEventDto) {}
