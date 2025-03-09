import {
  Column,
  Model,
  Table,
  ForeignKey,
  BelongsTo,
  DataType,
} from 'sequelize-typescript';
import { Case } from './case.model';
import { Team } from './team.model';
import { User } from './user.model';

@Table({
  tableName: 'documents',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
})
export class Document extends Model {
  @Column({
    primaryKey: true,
    autoIncrement: true,
    type: DataType.INTEGER,
  })
  id: number;

  @ForeignKey(() => Case)
  @Column({
    allowNull: false,
    field: 'case_id',
    type: DataType.INTEGER,
  })
  caseId: number;

  @ForeignKey(() => Team)
  @Column({
    field: 'team_id',
    type: DataType.INTEGER,
  })
  teamId: number;

  @ForeignKey(() => User)
  @Column({
    allowNull: false,
    field: 'user_id',
    type: DataType.INTEGER,
  })
  userId: number;

  @Column({
    allowNull: false,
    type: DataType.STRING(255),
  })
  title: string;

  @Column({
    field: 'file_path',
    type: DataType.STRING(255),
  })
  filePath: string;

  @Column({
    type: DataType.TEXT,
  })
  content: string;

  @Column({
    allowNull: false,
    field: 'document_type',
    type: DataType.STRING(50),
  })
  documentType: string;

  @Column({
    defaultValue: false,
    field: 'is_public',
    type: DataType.BOOLEAN,
  })
  isPublic: boolean;

  @Column({
    field: 'submitted_at',
    type: DataType.DATE,
    defaultValue: DataType.NOW,
  })
  submittedAt: Date;

  // Relationships
  @BelongsTo(() => Case, 'case_id')
  case: Case;

  @BelongsTo(() => Team, 'team_id')
  team: Team;

  @BelongsTo(() => User, 'user_id')
  user: User;
}
