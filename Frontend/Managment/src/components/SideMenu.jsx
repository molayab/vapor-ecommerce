
import { useEffect, useState } from 'react';
import userIcon from '/users.svg';
import activityIcon from '/activity.svg';
import truckIcon from '/truck.svg';
import packageIcon from '/package.svg';
import settingsIcon from '/settings.svg';
import posIcon from '/pos.svg';
import { Navigate, useNavigate } from 'react-router-dom';
import { Button, Icon, Metric, Subtitle, TextInput, Title } from '@tremor/react';
import { CashIcon, SearchIcon } from '@heroicons/react/solid';

function SideMenu({ children }) {
  const [isOpen, setIsOpen] = useState(false);
  const navigate = useNavigate();

  const [user, setUser] = useState({});
  const signout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  }

  useEffect(() => {
    const user = localStorage.getItem('user')
    if (!user) { return navigate('/login') }

    setUser(JSON.parse(user))
  }, [])

  return (
    <div className='p-4'>
      <nav className='p-4 bg-tremor-background-emphasis fixed z-10 w-full top-0 left-0'>
        <div className='flex w-full gap-4'>
          <div className='flex-col justify-center items-center hidden sm:flex'>
            <Metric className='text-white'>Vapor</Metric>
            <Subtitle className='text-white'>Ecommerce</Subtitle>
          </div>
          <div className='flex-1 items-end'>
            <ul className='flex gap-2 [&>li]:flex [&>li]:gap-1 [&>li]:pb-2 [&>li]:cursor-pointer [&>li]:text-tremor-content-inverted'>
              <li onClick={ () => navigate("/") }>
                <img src={activityIcon} alt='activity' />
                <span className='hidden md:block hover:underline'>Estadisticas</span>
              </li>
              <li onClick={ () => navigate("/pos") } className='mr-6'>
                <img src={posIcon} alt='pos' />
                <span className='hidden md:block hover:underline'>POS</span>
              </li>
              <li onClick={ () => navigate("/orders") }  >
                <img src={truckIcon} alt='truck' />
                <span className='hidden md:block hover:underlin'>Ordenes</span>
              </li>
              <li onClick={ () => navigate("/products") }>
                <img src={packageIcon} alt='package' />
                <span className='hidden md:block hover:underline'>Catalogo</span>
              </li>
              <li onClick={ () => navigate("/users") }>
                <img src={userIcon} alt='user' />
                <span className='hidden md:block hover:underline'>Usuarios</span>
              </li>
              <li>
                <img src={settingsIcon} alt='settings' />
                <span className='hidden md:block hover:underline'>Ajustes</span>
              </li>
            </ul>
            <TextInput icon={SearchIcon} className='w-full hover:bg-dark-tremor-background-emphasis bg-dark-tremor-background-emphasis' placeholder='Search...' />
          </div>
          <div className='flex flex-col items-center'>
            <span className='text-white'>Hola,</span>
            <small className='text-white'>{ user.email }</small>
            <Button size='xs' variant='light' onClick={(e) => signout() }>Salir</Button>
          </div>
        </div>
      </nav>

      <main className='w-full mt-24'>
        { children }
      </main>
    </div>
  );
}

export default SideMenu;