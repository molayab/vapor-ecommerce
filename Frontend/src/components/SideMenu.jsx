import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button, Card, Icon, Metric, Subtitle } from '@tremor/react'
import { GlobeIcon } from '@heroicons/react/solid'

import userIcon from '../../public/users.svg'
import activityIcon from '../../public/activity.svg'
import truckIcon from '../../public/truck.svg'
import packageIcon from '../../public/package.svg'
import settingsIcon from '../../public/settings.svg'
import posIcon from '../../public/pos.svg'

const { localStorage, sessionStorage } = window

function SideMenu ({ children }) {
  const [isOpen, setIsOpen] = useState(false)
  const settings = JSON.parse(sessionStorage.getItem('settings') || '{ "siteName": "Vapor Commerce" }')
  const navigate = useNavigate()

  const [user, setUser] = useState({})
  const signout = () => {
    sessionStorage.removeItem('token')
    localStorage.removeItem('user')
    navigate('/login')
  }

  useEffect(() => {
    const user = localStorage.getItem('user')
    if (!user) { return navigate('/login') }

    setUser(JSON.parse(user))
  }, [])

  return (
    <div className='p-4'>
      <nav className='p-4 bg-tremor-content-strong fixed z-50 w-full top-0 left-0 shadow'>
        <div className='flex w-full gap-4'>
          <div className='flex-col justify-center items-center hidden sm:flex'>
            <Metric className='text-white'>{settings.siteName}</Metric>
            <Subtitle className='text-white'>Managment</Subtitle>
          </div>
          <div className='flex-1 mt-4'>
            <ul className='flex items-center gap-2 [&>li]:flex [&>li]:gap-1 [&>li]:pb-2 [&>li]:cursor-pointer [&>li]:text-tremor-content-inverted'>
              <li onClick={() => navigate('/')}>
                <img src={activityIcon} alt='activity' />
                <span className='hidden md:block hover:underline'><small>Estadisticas</small></span>
              </li>
              <li onClick={() => navigate('/pos')} className='mr-6'>
                <img src={posIcon} alt='pos' />
                <span className='hidden md:block hover:underline'><small>POS</small></span>
              </li>
              <li onClick={() => navigate('/products')}>
                <img src={packageIcon} alt='package' />
                <span className='hidden md:block hover:underline'><small>Catalogo</small></span>
              </li>
              {/* <li onClick={() => navigate('/promos')}>
                <img src={packageIcon} alt='package' />
                <span className='hidden md:block hover:underline'><small>Promociones</small></span>
  </li> */}
              <li onClick={() => navigate('/orders')}>
                <img src={truckIcon} alt='truck' />
                <span className='hidden md:block hover:underlin'><small>Ordenes</small></span>
              </li>
              <li onClick={() => navigate('/users')}>
                <img src={userIcon} alt='user' />
                <span className='hidden md:block hover:underline'><small>Usuarios</small></span>
              </li>
              <li onClick={() => navigate('/settings')}>
                <img src={settingsIcon} alt='settings' />
                <span className='hidden md:block hover:underline'><small>Ajustes</small></span>
              </li>
            </ul>
          </div>
          <div className='flex flex-col items-center'>
            <span className='text-white'>Hola,</span>
            <small className='text-white'>{user.email}</small>
            <Button size='xs' variant='light' onClick={(e) => signout()}>Salir</Button>
          </div>
        </div>
      </nav>

      <main className='w-full mt-28'>
        {children}
      </main>

      <Card decoration='bottom' color='purple' className='mt-2'>
        <div className='flex justify-between items-center gap-4'>
          <Subtitle className='flex-none'>Vapor Commerce (c) {new Date().getFullYear()}</Subtitle>
          <Subtitle className='flex-1'>
            Creado por <a href='https://github.com/molayab' target='_blank' rel='noreferrer' className='underline'>@molayab</a> | Gracias a <a href='https://www.tremor.so/' target='_blank' rel='noreferrer' className='underline'>@tremor</a> por el diseño.
          </Subtitle>
          <Button variant='light' size='xs' onClick={() => setIsOpen(!isOpen)}>
            <Icon icon={GlobeIcon} />
          </Button>
        </div>
      </Card>
    </div>
  )
}

export default SideMenu
