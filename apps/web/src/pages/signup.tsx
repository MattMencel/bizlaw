import { signIn } from 'next-auth/react';

export default function SignUp() {
  const handleGoogleSignUp = () => {
    signIn('google');
  };

  return (
    <div>
      <h1>Sign Up</h1>
      <button onClick={handleGoogleSignUp}>Sign Up with Google</button>
    </div>
  );
}
