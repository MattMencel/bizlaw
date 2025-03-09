import { useState, useEffect } from 'react';
import axios from 'axios';

interface Instructor {
  name: string;
  email: string;
}

const Instructors = () => {
  const [instructors, setInstructors] = useState<Instructor[]>([]);
  const [email, setEmail] = useState('');

  useEffect(() => {
    axios.get('/api/instructors').then((response) => {
      setInstructors(response.data);
    });
  }, []);

  const inviteInstructor = () => {
    axios.post('/api/invite', { email }).then(() => {
      alert('Invitation sent');
      setEmail('');
    });
  };

  return (
    <div>
      <h2>Manage Instructors</h2>
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <button onClick={inviteInstructor}>Invite Instructor</button>
      <ul>
        {instructors.map((instructor, index) => (
          <li key={index}>
            {instructor.name} ({instructor.email})
          </li>
        ))}
      </ul>
    </div>
  );
};

export default Instructors;
