import {
  Column,
  Model,
  Table,
  ForeignKey,
  BelongsTo,
  HasMany,
  DataType,
} from 'sequelize-typescript';
import { Course } from './course.model';
import { Team } from './team.model';
import { CaseEvent } from './case-event.model';
import { Document } from './document.model';

@Table({
  tableName: 'cases',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
})
export class Case extends Model {
  @Column({
    primaryKey: true,
    autoIncrement: true,
    type: DataType.INTEGER,
  })
  id: number;

  @ForeignKey(() => Course)
  @Column({
    allowNull: false,
    field: 'course_id',
    type: DataType.INTEGER,
  })
  courseId: number;

  @Column({
    allowNull: false,
    type: DataType.STRING(255),
  })
  title: string;

  @Column({
    type: DataType.TEXT,
  })
  description: string;

  @Column({
    allowNull: false,
    defaultValue: 'draft',
    type: DataType.STRING(20),
  })
  status: 'draft' | 'active' | 'completed';

  @Column({
    field: 'start_date',
    type: DataType.DATE,
  })
  startDate: Date;

  @Column({
    field: 'end_date',
    type: DataType.DATE,
  })
  endDate: Date;

  // Relationships
  @BelongsTo(() => Course, 'course_id')
  course: Course;

  @HasMany(() => Team, 'case_id')
  teams: Team[];

  @HasMany(() => CaseEvent, 'case_id')
  events: CaseEvent[];

  @HasMany(() => Document, 'case_id')
  documents: Document[];
}
