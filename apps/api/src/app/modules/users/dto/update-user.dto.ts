export class UpdateUserDto {
  email?: string;
  password?: string;
  firstName?: string;
  lastName?: string;
  role?: 'student' | 'professor' | 'admin';
}
