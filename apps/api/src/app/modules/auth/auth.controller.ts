import { Controller, Get, Post, UseGuards, Req, Body } from '@nestjs/common';
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
}
