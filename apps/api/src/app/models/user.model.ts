import { Column, Model, Table, HasMany, DataType } from 'sequelize-typescript';
import { Course } from './course.model';
import { TeamMember } from './team-member.model';
import { Document } from './document.model';

@Table({
  tableName: 'users',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
})
export class User extends Model {
  @Column({
    primaryKey: true,
    autoIncrement: true,
    type: DataType.INTEGER,
  })
  id: number;

  @Column({
    allowNull: false,
    unique: true,
    type: DataType.STRING(100),
  })
  email: string;

  @Column({
    allowNull: false,
    type: DataType.STRING(255),
  })
  password: string;

  @Column({
    allowNull: false,
    field: 'first_name',
    type: DataType.STRING(50),
  })
  firstName: string;

  @Column({
    allowNull: false,
    field: 'last_name',
    type: DataType.STRING(50),
  })
  lastName: string;

  @Column({
    allowNull: false,
    type: DataType.STRING(20),
  })
  role: 'professor' | 'student' | 'admin';

  // Relationships
  @HasMany(() => Course, 'professor_id')
  courses: Course[];

  @HasMany(() => TeamMember, 'student_id')
  teamMembers: TeamMember[];

  @HasMany(() => Document, 'user_id')
  documents: Document[];
}
