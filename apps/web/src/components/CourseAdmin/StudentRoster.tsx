const StudentRoster = () => {
  // Fetch and display the student roster
  // This is a placeholder implementation
  const students = [
    { id: 1, name: 'Student 1', email: 'student1@example.com' },
    { id: 2, name: 'Student 2', email: 'student2@example.com' },
  ];

  return (
    <div>
      <h2>Student Roster</h2>
      <ul>
        {students.map((student) => (
          <li key={student.id}>
            {student.name} ({student.email})
          </li>
        ))}
      </ul>
    </div>
  );
};

export default StudentRoster;
