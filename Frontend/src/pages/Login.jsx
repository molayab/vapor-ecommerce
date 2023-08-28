import Header from "../components/Header";
import { API_URL, getAllFeatureFlags } from "../App";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button, Card, Grid, Subtitle, TextInput, Title, Callout, Text } from "@tremor/react";
import { usePostHog } from "posthog-js/react";

function Login() {
  const postHog = usePostHog()
  const navigate = useNavigate()
  const [errorDescriptionState, setErrorDescriptionState] = useState(undefined)

  const onSubmit = async (e) => {
    e.preventDefault();

    const payload = {
      username: e.target.email.value,
      password: e.target.password.value
    };

    const response = await fetch(API_URL + '/auth/create', {
      credentials: 'include',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await response.json()

    if (data.accessToken) {
      postHog.identify(data.user.id, {
        email: data.user.email,
      })
      postHog.group('role', data.user.rolesString)

      sessionStorage.setItem('token', data.accessToken);
      localStorage.setItem('user', JSON.stringify(data.user))

      postHog.capture('login-success', {
        email: data.user.email,
        role: data.user.rolesString,
      })
      navigate('/dashboard');
    } else if (data.error) {
      setErrorDescriptionState(data.reason);
      postHog.capture('login-failed', {
        email: payload.username,
        reason: data.reason,
      })
    }
  }

  return (
    <>
      <div className="h-screen w-screen flex items-center justify-center">
        <Card className="w-96">
          <form onSubmit={onSubmit}>
            <Title>Panel de gestión de tu e-commerce.</Title>
            <Subtitle>Ingresa a tu cuenta</Subtitle>

            {errorDescriptionState && (
              <Callout className="mt-4" color="rose" title="Error">
                <Text>{errorDescriptionState}</Text>
              </Callout>
            )}

            <TextInput className="mt-4" placeholder="Email" name="email" label="Email" required />
            <TextInput className="mt-4" placeholder="Password" name="password" label="Password" type="password" required />

            <Button className="mt-4 w-full" type="submit">Login</Button>
          </form>
        </Card>
      </div>
    </>
    
  );
}

export default Login;