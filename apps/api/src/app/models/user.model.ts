import {
  Table,
  Column,
  Model,
  DataType,
  HasMany, // Add this import
} from 'sequelize-typescript';
import { Course } from './course.model';
import { TeamMember } from './team-member.model';
import { Document } from './document.model';

@Table({
  tableName: 'users',
  underscored: true, // This tells Sequelize to use snake_case in the database
  timestamps: true,
})
export class User extends Model {
  @Column({
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
    primaryKey: true,
  })
  id: string;

  @Column({
    type: DataType.STRING,
    allowNull: false,
    unique: true,
  })
  email: string;

  @Column({
    type: DataType.STRING,
    allowNull: true,
  })
  password: string;

  @Column({
    type: DataType.STRING,
    allowNull: true,
    field: 'first_name', // Explicitly map to snake_case column
  })
  firstName: string;

  @Column({
    type: DataType.STRING,
    allowNull: true,
    field: 'last_name', // Explicitly map to snake_case column
  })
  lastName: string;

  @Column({
    type: DataType.STRING,
    allowNull: false,
    defaultValue: 'student',
  })
  role: string;

  @Column({
    type: DataType.STRING,
    allowNull: true,
    field: 'profile_image', // Explicitly map to snake_case column
  })
  profileImage: string;

  // Relationships
  @HasMany(() => Course, 'professor_id')
  courses: Course[];

  @HasMany(() => TeamMember, 'student_id')
  teamMembers: TeamMember[];

  @HasMany(() => Document, 'user_id')
  documents: Document[];
}
