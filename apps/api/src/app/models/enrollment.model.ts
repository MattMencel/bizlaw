import {
  Column,
  Model,
  Table,
  ForeignKey,
  BelongsTo,
  DataType,
} from 'sequelize-typescript';
import { Course } from './course.model';
import { User } from './user.model';

@Table({
  tableName: 'enrollments',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
})
export class Enrollment extends Model {
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

  @ForeignKey(() => User)
  @Column({
    allowNull: false,
    field: 'student_id',
    type: DataType.INTEGER,
  })
  studentId: number;

  // Relationships
  @BelongsTo(() => Course, 'course_id')
  course: Course;

  @BelongsTo(() => User, 'student_id')
  student: User;
}
