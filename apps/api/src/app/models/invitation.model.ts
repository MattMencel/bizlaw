import { Column, Model, Table, DataType } from 'sequelize-typescript';

@Table({
  tableName: 'invitations',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
})
export class Invitation extends Model {
  @Column({
    primaryKey: true,
    autoIncrement: true,
    type: DataType.INTEGER,
  })
  id = 0;

  @Column({
    allowNull: false,
    type: DataType.STRING(255),
  })
  email = '';

  @Column({
    allowNull: false,
    type: DataType.BOOLEAN,
    defaultValue: false,
  })
  accepted = false;
}
