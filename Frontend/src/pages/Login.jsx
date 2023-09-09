import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { usePostHog } from 'posthog-js/react'
import {
  Button,
  Card,
  Subtitle,
  TextInput,
  Title,
  Callout,
  Text
} from '@tremor/react'
import { request } from '../services/request'

const { localStorage, sessionStorage } = window

function Login () {
  const postHog = usePostHog()
  const navigate = useNavigate()
  const [errorDescriptionState, setErrorDescriptionState] = useState(undefined)

  const onSubmit = async (e) => {
    e.preventDefault()

    request.post('/auth/create', {
      username: e.target.email.value,
      password: e.target.password.value
    }).then((response) => {
      const data = response.data || {}
      if (data.accessToken) {
        postHog.identify(data.user.id, {
          email: data.user.email
        })
        postHog.group('role', data.user.rolesString)

        sessionStorage.setItem('token', data.accessToken)
        localStorage.setItem('user', JSON.stringify(data.user))

        postHog.capture('login-success', {
          email: data.user.email,
          role: data.user.rolesString
        })
        navigate('/dashboard')
      }
    }).catch((error) => {
      if (error.response) {
        setErrorDescriptionState(error.response.data.reason)
        postHog.capture('login-failed', {
          email: e.target.email.value,
          reason: error.response.data.reason
        })
      }
    })
  }

  return (
    <>
      <div className='h-screen w-screen flex items-center justify-center'>
        <Card className='w-96'>
          <form onSubmit={onSubmit}>
            <Title>Panel de gestión de tu e-commerce.</Title>
            <Subtitle>Ingresa a tu cuenta</Subtitle>

            {errorDescriptionState && (
              <Callout className='mt-4' color='rose' title='Error'>
                <Text>{errorDescriptionState}</Text>
              </Callout>
            )}

            <TextInput className='mt-4' placeholder='Email' name='email' label='Email' required />
            <TextInput className='mt-4' placeholder='Password' name='password' label='Password' type='password' required />

            <Button className='mt-4 w-full' type='submit'>Login</Button>
          </form>
        </Card>
      </div>
    </>

  )
}

export default Login
