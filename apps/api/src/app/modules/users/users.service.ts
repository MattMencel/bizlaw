import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import * as bcrypt from 'bcryptjs';
import { User } from '../../models';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User)
    private userModel: typeof User,
  ) {}

  async findAll(): Promise<User[]> {
    return this.userModel.findAll({
      attributes: { exclude: ['password'] },
    });
  }

  async findOne(id: number): Promise<User> {
    return this.userModel.findByPk(id, {
      attributes: { exclude: ['password'] },
    });
  }

  async findByEmail(email: string): Promise<User> {
    return this.userModel.findOne({
      where: { email },
    });
  }

  async create(userData: {
    email: string;
    password: string;
    firstName: string;
    lastName: string;
    role: 'professor' | 'student' | 'admin';
  }): Promise<User> {
    const hashedPassword = await bcrypt.hash(userData.password, 10);

    return this.userModel.create({
      ...userData,
      password: hashedPassword,
    });
  }

  async update(id: number, userData: Partial<User>): Promise<[number, User[]]> {
    if (userData.password) {
      userData.password = await bcrypt.hash(userData.password, 10);
    }

    return this.userModel.update(userData, {
      where: { id },
      returning: true,
    });
  }

  async remove(id: number): Promise<void> {
    await this.userModel.destroy({
      where: { id },
    });
  }
}
