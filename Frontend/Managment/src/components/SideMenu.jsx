
import { useState } from 'react';
import userIcon from '/users.svg';
import activityIcon from '/activity.svg';
import truckIcon from '/truck.svg';
import packageIcon from '/package.svg';
import settingsIcon from '/settings.svg';
import posIcon from '/pos.svg';
import { Navigate, useNavigate } from 'react-router-dom';
import { Icon, Metric, Title } from '@tremor/react';
import { CashIcon } from '@heroicons/react/solid';

function SideMenu({ children }) {
  const [isOpen, setIsOpen] = useState(false);
  const navigate = useNavigate();

  return (
    <div className='p-4'>
      <nav className='p-4 bg-tremor-background-emphasis'>
        <div className='grid grid-flow-col'>
          <div>
            <Metric className='text-white'>Vapor</Metric>
            <Title className='text-white'>Ecommerce</Title>
          </div>
          <div>
            <ul className='flex flex-row-reverse gap-2 [&>li]:flex [&>li]:gap-2 [&>li]:py-1 [&>li]:cursor-pointer'>
              <li>
                <img src={settingsIcon} alt='settings' />
                <span>Settings</span>
              </li>
              <li>
                <img src={truckIcon} alt='truck' />
                <span>Orders</span>
              </li>
              <li onClick={ () => navigate("/pos") }>
                <img src={posIcon} alt='' />
                <span>POS</span>
              </li>
              <li onClick={ () => navigate("/products") }>
                <img src={packageIcon} alt='package' />
                <span>Products</span>
              </li>
              <li onClick={ () => navigate("/users") }>
                <img src={userIcon} alt='user' />
                <span>Users</span>
              </li>
              <li onClick={ () => navigate("/") }>
                <img src={activityIcon} alt='activity' />
                <span>Dashboard</span>
              </li>
            </ul>
          </div>
          
        </div>
      </nav>

      <main className='w-full'>
        { children }
      </main>
    </div>
  );
}

export default SideMenu;