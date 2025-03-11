import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/sequelize';
import * as bcrypt from 'bcryptjs';
import { User, Invitation } from '../../models';
import { UserData, LoginResponse } from './types/auth.types';

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

  // Combined login method that accepts either a full user object or just email
  async login(
    userOrEmail: UserData | { email: string },
  ): Promise<LoginResponse> {
    let user: User | null;

    if ('id' in userOrEmail) {
      // If userOrEmail has an id property, it's already a full user object
      const payload = {
        email: userOrEmail.email,
        sub: userOrEmail.id,
        role: userOrEmail.role,
      };

      return {
        accessToken: this.jwtService.sign(payload),
        user: {
          id: userOrEmail.id,
          email: userOrEmail.email,
          firstName: userOrEmail.firstName,
          lastName: userOrEmail.lastName,
          role: userOrEmail.role,
        },
      };
    } else {
      // If only email is provided, find the user first
      user = await this.findUserByEmail(userOrEmail.email);

      if (!user) {
        throw new Error('User not found');
      }

      return this.generateToken(user);
    }
  }

  // Add the findUserByEmail method
  async findUserByEmail(email: string): Promise<User | null> {
    return this.userModel.findOne({
      where: { email },
    });
  }

  // Add the generateToken method
  async generateToken(user: User) {
    const payload = {
      email: user.email,
      sub: user.id,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
    };

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
        console.log(`User found: ${user.id}, role: ${user.role}`);
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
        console.log(`User count: ${userCount}`);
        if (userCount === 0) {
          role = 'admin'; // First user gets admin role
          console.log('Setting first user as admin');
        }
      }

      // Parse the name
      const nameParts = name ? name.split(' ') : ['User', ''];
      const firstName = nameParts[0];
      const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';

      // Create a random password for OAuth users
      const randomPassword = Math.random().toString(36).slice(-8);
      const hashedPassword = await bcrypt.hash(randomPassword, 10);

      // Create the user with explicit values for all required fields
      console.log(`Creating new user with email: ${email}, role: ${role}`);

      user = await this.userModel.create({
        email,
        firstName,
        lastName,
        password: hashedPassword,
        role,
        // Only set profileImage if the column exists in the database
        ...(image ? { profileImage: image } : {}),
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
