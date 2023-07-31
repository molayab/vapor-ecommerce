import Header from "../components/Header";
import SideMenu from "../components/SideMenu";

function Dashboard() {
  return (
    <>
      <Header />
      <SideMenu>
        <main className=''>
          <h1>Dashboard</h1>
          <nav className='flex flex-col gap-2'>
            <article className=''>
              <h2 className='text-xl font-bold'>Orders</h2>
              <ul className='flex flex-col gap-2'>
                <li className='flex flex-row gap-2'>
                  <span className='w-1/2'>Total orders</span>
                  <span className='w-1/2'>100</span>
                </li>
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
  );
}

export default Dashboard;