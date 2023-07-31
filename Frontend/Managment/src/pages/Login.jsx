import Header from "../components/Header";
import { API_URL } from "../App";
import { useEffect } from "react";

function Login() {
  const onSubmit = async (e) => {
    e.preventDefault();

    if (e.target.email.value === "" || e.target.password.value === "") {
      const errorZone = document.getElementById("hello");
      errorZone.classList.remove("hidden");
      errorZone.innerHTML = "Please fill in all fields";

      return;
    }

    const payload = {
      username: e.target.email.value,
      password: e.target.password.value
    };

    const response = await fetch(API_URL + '/auth/create', {
      credentials: 'include',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    if (data.accessToken) {
      localStorage.setItem('token', data.accessToken);
      window.location.href = '/dashboard';
    } else if (data.error) {
      const errorZone = document.getElementById("hello");
      errorZone.classList.remove("hidden");
      errorZone.innerHTML = data.reason;
    }
  }

  return (
    <>
      <div className='flex flex-col items-center justify-center h-screen'>
        <h1 className='text-4xl font-bold'>Login</h1>
        <div id="hello" className='hidden'>
          <p className='text-red-500'>Invalid credentials</p>
        </div>
        <form className='flex flex-col gap-2 mt-4' onSubmit={(e) => onSubmit(e) }>
          <input type='email' name="email" placeholder='Email' className='p-2 rounded-md' />
          <input type='password' name="password" placeholder='Password' className='p-2 rounded-md' />
          <button type='submit' className='p-2 rounded-md bg-gray-200 hover:bg-gray-300'>Login</button>
        </form>
      </div>
    </>
    
  );
}

export default Login;