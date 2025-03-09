import { useEffect, useState } from 'react';
import axios from 'axios';

const HelloApiComponent = () => {
  const [message, setMessage] = useState('');

  useEffect(() => {
    axios
      .get(`${process.env.NEXT_PUBLIC_API_URL}/health`)
      .then((response) => {
        setMessage(response.data.message);
      })
      .catch((error) => {
        console.error('There was an error fetching the message!', error);
      });
  }, []);

  return (
    <div>
      <h1>{message}</h1>
    </div>
  );
};

export default HelloApiComponent;
