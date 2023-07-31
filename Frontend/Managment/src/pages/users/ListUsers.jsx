import Header from "../../components/Header"
import SideMenu from "../../components/SideMenu"
import { useNavigate } from "react-router-dom"
import SubHeader from "../../components/SubHeader";

function ListUsers() {
  const navigate = useNavigate();

  return (
      <>
        <Header />
        <SideMenu>
          <main className= 'w-full px-2 py-2'>
            <SubHeader title="Users">
              <button 
                onClick={() => navigate("/users/create") }
                className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                Add user
              </button>
              <button className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                Add user
              </button>
            </SubHeader>
            
            <nav className='flex flex-col gap-2'>
              <article className=''>
                <h2 className='text-xl font-bold'>Users</h2>
                <ul className='flex flex-col gap-2'>
                  <li className='flex flex-row gap-2'>
                    <span className='w-1/2'>Total users</span>
                    <span className='w-1/2'>0</span>
                  </li>
                  </ul>
              </article>
            </nav>
          </main>
        </SideMenu>
      </>
  )
}

export default ListUsers