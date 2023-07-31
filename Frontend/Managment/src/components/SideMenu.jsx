
import { useState } from 'react';
import userIcon from '/users.svg';
import activityIcon from '/activity.svg';
import truckIcon from '/truck.svg';
import packageIcon from '/package.svg';
import settingsIcon from '/settings.svg';
import { Navigate, useNavigate } from 'react-router-dom';

function SideMenu({ children }) {
  const [isOpen, setIsOpen] = useState(false);
  const navigate = useNavigate();

  return (
    <div className='flex'>
      <aside className={`bg-slate-300 ${isOpen ? 'w-40' : 'w-20'}`}>
        <div className='flex flex-col items-center h-screen'>
          <ul className='mt-2 
            [&>li]:flex [&>li]:gap-2 [&>li]:py-1 [&>li]:cursor-pointer'>
            <li>
              <img src={activityIcon} alt='activity' />
              <span className={ !isOpen ? "hidden" : "" }>Dashboard</span>
            </li>
            <li>
              <img src={truckIcon} alt='truck' />
              <span className={ !isOpen ? "hidden" : "" }>Orders</span>
            </li>
            <li onClick={ () => navigate("/products") }>
              <img src={packageIcon} alt='package' />
              <span className={ !isOpen ? "hidden" : "" }>Products</span>
            </li>
            <li onClick={ () => navigate("/users") }>
              <img src={userIcon} alt='user' />
              <span className={ !isOpen ? "hidden" : "" }>Users</span>
            </li>
            <li>
              <img src={settingsIcon} alt='settings' />
              <span className={ !isOpen ? "hidden" : "" }>Settings</span>
            </li>
          </ul>
        </div>
      </aside>

      <main className='w-full'>
        { children }
      </main>
    </div>
  );
}

export default SideMenu;