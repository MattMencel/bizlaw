import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { CaseEvent, Case } from '../../models';
import { CaseEventsService } from './case-events.service';
import { CaseEventsController } from './case-events.controller';

@Module({
  imports: [SequelizeModule.forFeature([CaseEvent, Case])],
  controllers: [CaseEventsController],
  providers: [CaseEventsService],
  exports: [CaseEventsService],
})
export class CaseEventsModule {}
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
