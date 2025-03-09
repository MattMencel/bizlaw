import {
  Column,
  Model,
  Table,
  ForeignKey,
  BelongsTo,
  DataType,
} from 'sequelize-typescript';
import { Team } from './team.model';
import { User } from './user.model';

@Table({
  tableName: 'team_members',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
})
export class TeamMember extends Model {
  @Column({
    primaryKey: true,
    autoIncrement: true,
    type: DataType.INTEGER,
  })
  id: number;

  @ForeignKey(() => Team)
  @Column({
    allowNull: false,
    field: 'team_id',
    type: DataType.INTEGER,
  })
  teamId: number;

  @ForeignKey(() => User)
  @Column({
    allowNull: false,
    field: 'student_id',
    type: DataType.INTEGER,
  })
  studentId: number;

  // Relationships
  @BelongsTo(() => Team, 'team_id')
  team: Team;

  @BelongsTo(() => User, 'student_id')
  student: User;
}
