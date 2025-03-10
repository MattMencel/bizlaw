import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/sequelize';
import * as bcrypt from 'bcryptjs';
import { User, Invitation } from '../../models';

// Define proper interfaces for type safety
interface UserData {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
}

interface LoginResponse {
  accessToken: string;
  user: UserData;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User)
    private userModel: typeof User,
    @InjectModel(Invitation)
    private invitationModel: typeof Invitation,
    private jwtService: JwtService,
  ) {}

  async validateUser(
    email: string,
    password: string,
  ): Promise<UserData | null> {
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

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password: passwordValue, ...result } = user.toJSON();
    return result;
  }

  async login(user: UserData): Promise<LoginResponse> {
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

  // In your NestJS auth service or controller
  async checkUser(
    email: string,
    name?: string,
    image?: string,
    checkFirstUser = false,
  ) {
    try {
      // Check if user exists
      let user = await this.userModel.findOne({
        where: { email },
        attributes: ['id', 'email', 'firstName', 'lastName', 'role'],
      });

      // If user exists, return their role
      if (user) {
        return {
          id: user.id,
          email: user.email,
          role: user.role,
        };
      }

      // If this is a new user, check if any users exist in the system
      let role = 'student'; // Default role

      if (checkFirstUser) {
        const userCount = await this.userModel.count();
        if (userCount === 0) {
          role = 'admin'; // First user gets admin role
        }
      }

      // Parse the name
      const nameParts = name ? name.split(' ') : ['User', ''];
      const firstName = nameParts[0];
      const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';

      // Create a random password for OAuth users
      const randomPassword = Math.random().toString(36).slice(-8);
      const hashedPassword = await bcrypt.hash(randomPassword, 10);

      // Create the user - THIS IS THE CRITICAL PART THAT MIGHT BE FAILING
      console.log(`Creating new user with email: ${email}, role: ${role}`);

      user = await this.userModel.create({
        email,
        firstName,
        lastName,
        password: hashedPassword,
        role,
        profileImage: image || null,
      });

      console.log(`User created successfully with ID: ${user.id}`);

      return {
        id: user.id,
        email: user.email,
        role: user.role,
      };
    } catch (error) {
      console.error('Error in checkUser method:', error);
      throw error; // Make sure to propagate the error
    }
  }
}
