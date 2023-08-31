import reactLogo from '../../public/default.svg'

function Header() {
  return (
    <nav className='flex flex-row gap-2 items-center bg-gray-400 w-full p-2'>
      <img src={reactLogo} className="react-logo" alt="react-logo" />
      <h1 className='text-xl font-bold'>Ecommerce Dashboard</h1>

      <div className='flex-grow'></div>
      <div className='flex-none'>
        <div className='flex gap-2'>
          <input type='text' className='p-2 rounded-md' placeholder='Search...' />
          <ul className='flex items-center gap-2'>
            <li>
              <a href='#' className='p-2 rounded-md bg-gray-200 hover:bg-gray-300'>Login</a>
            </li>
            <li>
              <a href='#' className='p-2 rounded-md bg-gray-200 hover:bg-gray-300'>Register</a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  );
}

export default Header;