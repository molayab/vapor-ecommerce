import ContainerCard from '../../../components/ContainerCard'
import SideMenu from '../../../components/SideMenu'
import CreateUserForm from './_components/CreateUserForm'
import { Button } from '@tremor/react'
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchAvailableCountryIds, fetchCountries } from '../../../services/countries'
import { createClientUser } from '../../../services/users'

function CreateClient () {
  const [roles] = useState([])
  const [countries, setCountries] = useState([])
  const [country, setCountry] = useState('')
  const [activated] = useState(0)
  const [nationalIdType, setNationalIdType] = useState('')
  const [nationalIds, setNationalIds] = useState([])

  const navigate = useNavigate()
  const fetchInitialData = async () => {
    let response
    response = await fetchCountries()
    setCountries(response.data)

    response = await fetchAvailableCountryIds()
    setNationalIds(response.data)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const randomPassword = Math.random().toString(36).slice(-8)
    const payload = {
      name: e.target.name.value,
      email: e.target.email.value,
      nationalIdType,
      nationalId: e.target.document.value,
      kind: 'client',
      roles,
      password: randomPassword,
      isActive: activated === 1,
      phone: e.target.telephone.value,
      cellphone: e.target.cellphone.value
    }

    const response = await createClientUser(
      country
        ? {
            ...payload,
            addresses: [{
              zip: e.target.zip.value,
              street: e.target.address.value,
              city: e.target.city.value,
              state: e.target.state.value,
              country
            }]
          }
        : { ...payload })
    if (response.status === 200) {
      navigate('/users')
    }
  }

  useEffect(() => {
    fetchInitialData()
  }, [])

  return (
    <form onSubmit={(e) => handleSubmit(e)}>
      <SideMenu>
        <ContainerCard
          title='Cliente' subtitle='Crear un nuevo'
          action={
            <Button
              type='submit'
              className='btn btn-primary'
            >Guardar
            </Button>
          }
        >
          <CreateUserForm
            nationalIds={nationalIds}
            setNationalIdType={setNationalIdType}
            countries={countries}
            setCountry={setCountry}
            country={country}
            nationalIdType={nationalIdType}
          />
        </ContainerCard>
      </SideMenu>
    </form>
  )
}

export default CreateClient
