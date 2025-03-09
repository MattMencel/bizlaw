import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsBoolean,
  IsDateString,
  IsInt,
} from 'class-validator';

export class CreateCaseEventDto {
  @IsInt()
  @IsNotEmpty()
  caseId: number;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsNotEmpty()
  eventType: string;

  @IsDateString()
  @IsNotEmpty()
  scheduledDate: Date;

  @IsBoolean()
  @IsOptional()
  isVisible?: boolean = true;
}
