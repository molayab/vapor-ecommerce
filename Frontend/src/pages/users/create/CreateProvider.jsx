import SideMenu from '../../../components/SideMenu'
import ContainerCard from '../../../components/ContainerCard'
import CreateUserForm from './_components/CreateUserForm'
import { Button } from '@tremor/react'
import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchAvailableCountryIds, fetchCountries } from '../../../services/countries'
import { createProviderUser } from '../../../services/users'

function CreateProvider () {
  const [countries, setCountries] = useState([])
  const [country, setCountry] = useState('')
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

    const payload = {
      name: e.target.name.value,
      email: e.target.email.value,
      nationalIdType,
      nationalId: e.target.document.value,
      phone: e.target.telephone.value,
      cellphone: e.target.cellphone.value,
      addresses: [{
        zip: e.target.zip.value,
        street: e.target.address.value,
        city: e.target.city.value,
        state: e.target.state.value,
        country
      }]
    }

    const response = await createProviderUser(payload)
    if (response.status === 200) {
      navigate('/users')
    }
  }

  useEffect(() => {
    fetchInitialData()
  }, [])

  return (
    <SideMenu>
      <form onSubmit={(e) => handleSubmit(e)} className='mt-4'>
        <ContainerCard
          title='Proveedor' subtitle='Crear un nuevo' action={
            <Button className='btn btn-primary'>Guardar</Button>
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
      </form>
    </SideMenu>
  )
}

export default CreateProvider
