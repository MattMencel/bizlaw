import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Reflector } from '@nestjs/core';

@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'your_jwt_secret_key',
      signOptions: { expiresIn: '60m' },
    }),
  ],
  providers: [
    Reflector,
    {
      provide: RolesGuard,
      useFactory: reflector => new RolesGuard(reflector),
      inject: [Reflector],
    },
  ],
  exports: [JwtModule, RolesGuard],
})
export class CommonModule {}
