import { redirect } from 'next/navigation';
import { getServerSession } from 'next-auth/next';

import ProfileForm from '@/components/profile/ProfileForm';
import { authOptions } from '@/lib/auth/auth';

export const metadata = {
  title: 'Profile | Business Law',
};

export default async function ProfilePage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect('/auth/signin?callbackUrl=/profile');
  }

  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Your Profile</h1>
      <ProfileForm user={session.user} />
    </div>
  );
}
