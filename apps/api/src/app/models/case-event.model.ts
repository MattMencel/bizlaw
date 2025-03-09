import {
  Column,
  Model,
  Table,
  ForeignKey,
  BelongsTo,
  DataType,
} from 'sequelize-typescript';
import { Case } from './case.model';

@Table({
  tableName: 'case_events',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
})
export class CaseEvent extends Model {
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
    type: DataType.STRING(255),
  })
  title: string;

  @Column({
    type: DataType.TEXT,
  })
  description: string;

  @Column({
    allowNull: false,
    field: 'event_type',
    type: DataType.STRING(50),
  })
  eventType: string;

  @Column({
    allowNull: false,
    field: 'scheduled_date',
    type: DataType.DATE,
  })
  scheduledDate: Date;

  @Column({
    defaultValue: true,
    field: 'is_visible',
    type: DataType.BOOLEAN,
  })
  isVisible: boolean;

  // Relationships
  @BelongsTo(() => Case, 'case_id')
  case: Case;
}
