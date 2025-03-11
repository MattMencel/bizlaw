export interface UserData {
  id: string; // Using string for UUID consistency
  email: string;
  firstName: string;
  lastName: string;
  role: string;
}

export interface LoginResponse {
  accessToken: string;
  user: UserData;
}
