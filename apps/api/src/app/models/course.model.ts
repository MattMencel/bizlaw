import {
  Column,
  Model,
  Table,
  ForeignKey,
  BelongsTo,
  HasMany,
  DataType,
} from 'sequelize-typescript';
import { User } from './user.model';
import { Enrollment } from './enrollment.model';
import { Case } from './case.model';

@Table({
  tableName: 'courses',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
})
export class Course extends Model {
  @Column({
    primaryKey: true,
    autoIncrement: true,
    type: DataType.INTEGER,
  })
  id: number;

  @Column({
    allowNull: false,
    type: DataType.STRING(100),
  })
  title: string;

  @Column({
    allowNull: false,
    type: DataType.STRING(20),
  })
  code: string;

  @Column({
    type: DataType.TEXT,
  })
  description: string;

  @ForeignKey(() => User)
  @Column({
    allowNull: false,
    field: 'professor_id',
    type: DataType.INTEGER,
  })
  professorId: number;

  @Column({
    allowNull: false,
    type: DataType.STRING(20),
  })
  semester: string;

  @Column({
    allowNull: false,
    type: DataType.INTEGER,
  })
  year: number;

  // Relationships
  @BelongsTo(() => User, 'professor_id')
  professor: User;

  @HasMany(() => Enrollment, 'course_id')
  enrollments: Enrollment[];

  @HasMany(() => Case, 'course_id')
  cases: Case[];
}
