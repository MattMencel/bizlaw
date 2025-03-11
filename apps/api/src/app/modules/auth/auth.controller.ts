import {
  Controller,
  Get,
  Post,
  UseGuards,
  Req,
  Body,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  getProfile(@Req() req) {
    return req.user;
  }

  @Post('check-user')
  async checkUser(
    @Body()
    body: {
      email: string;
      name?: string;
      image?: string;
      checkFirstUser?: boolean;
    },
  ) {
    return this.authService.checkUser(
      body.email,
      body.name,
      body.image,
      body.checkFirstUser,
    );
  }

  @Post('login')
  async login(@Body() loginDto: { email: string }) {
    console.log('Login attempt for:', loginDto.email);
    try {
      const user = await this.authService.findUserByEmail(loginDto.email);

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      const result = await this.authService.generateToken(user);
      console.log('Token generated successfully for user:', loginDto.email);
      return result;
    } catch (error) {
      console.error('Error during login:', error);
      throw new UnauthorizedException('Login failed');
    }
  }
}
