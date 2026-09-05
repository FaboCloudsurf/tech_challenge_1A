// import React, { useEffect, useState } from 'react'
// import './App.css';
// import API_URL from './config'

// function App() {
//   const [successMessage, setSuccessMessage] = useState() 
//   const [failureMessage, setFailureMessage] = useState() 

//   useEffect(() => {
//     const getId = async () => {
//       try {
//         const resp = await fetch(API_URL)
//         setSuccessMessage((await resp.json()).id)
//       }
//       catch(e) {
//         setFailureMessage(e.message)
//       }
//     }
//     getId()
//   })

//   return (
//     <div className="App">
//       {!failureMessage && !successMessage ? 'Fetching...' : null}
//       {failureMessage ? failureMessage : null}
//       {successMessage ? successMessage : null}
//     </div>
//   );
// }

// export default App;

function App() {
  const [guid, setGuid] = useState('');

  useEffect(() => {
    fetch(API_URL)
      .then(res => res.json())
      .then(data => setGuid(data.guid));
  }, []);

  return (
    <div>
      <p>{guid}</p>

      <iframe
        src="https://www.instagram.com/reel/C-8xr7Pq8gj/embed"
        width="400"
        height="480"
        frameBorder="0"
        scrolling="no"
        allowFullScreen
        title="Instagram Reel"
      ></iframe>
    </div>
  );
}