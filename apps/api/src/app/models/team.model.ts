import {
  Column,
  Model,
  Table,
  ForeignKey,
  BelongsTo,
  HasMany,
  DataType,
} from 'sequelize-typescript';
import { Case } from './case.model';
import { TeamMember } from './team-member.model';
import { Document } from './document.model';

@Table({
  tableName: 'teams',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
})
export class Team extends Model {
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

  @Column({
    allowNull: false,
    type: DataType.STRING(100),
  })
  name: string;

  @Column({
    allowNull: false,
    type: DataType.STRING(50),
  })
  role: 'plaintiff' | 'defendant' | 'judge';

  // Relationships
  @BelongsTo(() => Case, 'case_id')
  case: Case;

  @HasMany(() => TeamMember, 'team_id')
  members: TeamMember[];

  @HasMany(() => Document, 'team_id')
  documents: Document[];
}
