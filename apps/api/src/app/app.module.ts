import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { SequelizeModule } from '@nestjs/sequelize';
import databaseConfig from './config/database.config';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CasesModule } from './modules/cases/cases.module';
import { CaseEventsModule } from './modules/case-events/case-events.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import {
  User,
  Course,
  Enrollment,
  Case,
  Team,
  TeamMember,
  CaseEvent,
  Document,
  Invitation,
} from './models'; // Ensure Invitation is imported

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig],
    }),
    SequelizeModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) =>
        configService.get('database'),
    }),
    SequelizeModule.forFeature([
      User,
      Course,
      Enrollment,
      Case,
      Team,
      TeamMember,
      CaseEvent,
      Document,
      Invitation,
    ]), // Ensure Invitation is included
    UsersModule,
    AuthModule,
    CasesModule,
    CaseEventsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
