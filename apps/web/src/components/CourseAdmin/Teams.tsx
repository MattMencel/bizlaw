import { useState } from 'react';

const Teams = () => {
  const [teams, setTeams] = useState([
    { id: 1, name: 'Plaintiff' },
    { id: 2, name: 'Defendant' },
  ]);

  const [teamName, setTeamName] = useState('');

  const handleAddTeam = () => {
    const newTeam = { id: teams.length + 1, name: teamName };
    setTeams([...teams, newTeam]);
    setTeamName('');
  };

  const handleDeleteTeam = (id: number) => {
    setTeams(teams.filter((team) => team.id !== id));
  };

  return (
    <div>
      <h2>Teams</h2>
      <ul>
        {teams.map((team) => (
          <li key={team.id}>
            {team.name}
            <button onClick={() => handleDeleteTeam(team.id)}>Delete</button>
          </li>
        ))}
      </ul>
      <input
        type="text"
        value={teamName}
        onChange={(e) => setTeamName(e.target.value)}
        placeholder="New team name"
      />
      <button onClick={handleAddTeam}>Add Team</button>
    </div>
  );
};

export default Teams;
