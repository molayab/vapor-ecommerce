import SideMenu from '../../components/SideMenu'
import { useNavigate } from 'react-router-dom'
import { Grid, Flex, Button, TextInput, TabGroup, TabList, Tab, TabPanels, TabPanel } from '@tremor/react'
import { UserGroupIcon, UserIcon } from '@heroicons/react/outline'
import ContainerCard from '../../components/ContainerCard'
import { useEffect, useState } from 'react'
import UsersTable from '../../components/UsersTable'
import { fetchClients, fetchEmployees, fetchProviders } from '../../services/users'
import Loader from '../../components/Loader'

function ListUsers () {
  const navigate = useNavigate()
  const [users, setUsers] = useState({ items: [] })
  const [page, setPage] = useState(1)
  const [currentTab, setCurrentTab] = useState(0)

  const fetchUsers = async (filter, page) => {
    switch (filter) {
      case 'clients':
        setUsers((await fetchClients(page)).data)
        break
      case 'employees':
        setUsers((await fetchEmployees(page)).data)
        break
      case 'providers':
        setUsers((await fetchProviders(page)).data)
        break
      default:
        break
    }
  }

  const onIndexChange = (index, page) => {
    setCurrentTab(index)
    switch (index) {
      case 0:
        fetchUsers('clients', page)
        break
      case 1:
        fetchUsers('employees', page)
        break
      case 2:
        fetchUsers('providers', page)
        break
      default:
        break
    }
  }

  const nextPage = () => {
    setPage(prev => prev + 1)
    onIndexChange(currentTab, page + 1)
  }

  const prevPage = () => {
    setPage(prev => prev - 1)
    onIndexChange(currentTab, page - 1)
  }

  const [localUsers, setLocalUsers] = useState([])

  useEffect(() => {
    onIndexChange(currentTab, 1)
    setLocalUsers(users.items)
  }, [localUsers])

  if (users == null || localUsers === null) {
    return (<Loader />)
  }

  return (
    <>
      <SideMenu>
        <ContainerCard
          title='Usuarios'
          subtitle='Administrador de'
          action={
            <Grid numItems={1} numItemsLg={3} numItemsMd={1} className='gap-1'>
              <Button onClick={() => navigate('/users/new/client')}>Nuevo Cliente</Button>
              <Button onClick={() => navigate('/users/new/provider')}>Nuevo Proveedor</Button>
              <Button onClick={() => navigate('/users/new/employee')}>Nuevo Empleado</Button>
            </Grid>
            }
        >

          <TabGroup onIndexChange={(e) => onIndexChange(e, page)}>
            <TabList className='mt-8'>
              <Tab icon={UserGroupIcon}>Clientes</Tab>
              <Tab icon={UserIcon}>Empleados</Tab>
              <Tab icon={UserIcon}>Proveedores</Tab>
            </TabList>
            <TabPanels>
              <TabPanel>
                <UsersTable users={users.items} setUsers={setLocalUsers} />
              </TabPanel>
              <TabPanel>
                <UsersTable users={users.items} setUsers={setLocalUsers} />
              </TabPanel>
              <TabPanel>
                <UsersTable users={users.items} setUsers={setLocalUsers} />
              </TabPanel>
            </TabPanels>
          </TabGroup>

          <Flex justifyContent='end' className='space-x-2 pt-4 mt-8'>
            <Button size='xs' variant='secondary' onClick={prevPage} disabled={page === 1}>
              Anterior
            </Button>

            <TextInput size='xs' className='w-10' value={page} readOnly />

            <Button size='xs' variant='primary' onClick={nextPage} disabled={page === (users.total / users.per).toFixed()}>
              Siguiente
            </Button>
          </Flex>
        </ContainerCard>
      </SideMenu>
    </>
  )
}

export default ListUsers
