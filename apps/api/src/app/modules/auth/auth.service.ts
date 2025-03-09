import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/sequelize';
import * as bcrypt from 'bcryptjs';
import { User } from '../../models';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User)
    private userModel: typeof User,
    private jwtService: JwtService,
  ) {}

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.userModel.findOne({
      where: { email },
      attributes: ['id', 'email', 'password', 'firstName', 'lastName', 'role'],
    });

    if (!user) {
      return null;
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return null;
    }

    const { password: _, ...result } = user.toJSON();
    return result;
  }

  async validateOAuthLogin(
    email: string,
    firstName: string,
    lastName: string,
  ): Promise<any> {
    let user = await this.userModel.findOne({ where: { email } });

    if (!user) {
      user = await this.userModel.create({
        email,
        firstName,
        lastName,
        role: 'instructor',
      });
    }

    const { password: _, ...result } = user.toJSON();
    return result;
  }

  async login(user: any) {
    const payload = { email: user.email, sub: user.id, role: user.role };
    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
      },
    };
  }
}
