import ContainerCard from "../../../components/ContainerCard"
import SideMenu from "../../../components/SideMenu"
import CreateUserForm from "./_components/CreateUserForm"
import { Button } from "@tremor/react"
import { useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"
import { API_URL } from "../../../App"

function CreateClient() {
    const [roles, setRoles] = useState([]);
    const [allRoles, setAllRoles] = useState([]);
    const [countries, setCountries] = useState([]);
    const [country, setCountry] = useState('');
    const [activated, setActivated] = useState(0);
    const [nationalIdType, setNationalIdType] = useState('');
    const [nationalIds, setNationalIds] = useState([]);

    const navigate = useNavigate();

    const fetchInitialData = async () => {
        let response
        response = await fetch(API_URL + '/countries', {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json'
            }
        })
        setCountries(await response.json())

        response = await fetch(API_URL + '/users/available/roles', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        })
        setAllRoles(await response.json())

        response = await fetch(API_URL + '/users/available/national/ids', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        })
        setNationalIds(await response.json())
    }

    const handleSubmit = async (e) => {
        e.preventDefault()
        let randomPassword = Math.random().toString(36).slice(-8);
        const payload = {
            name: e.target.name.value,
            email: e.target.email.value,
            nationalIdType: nationalIdType,
            nationalId: e.target.document.value,
            kind: "client",
            roles: roles,
            password: randomPassword,
            isActive: activated === 1 ? true : false,
            phone: e.target.telephone.value,
            cellphone: e.target.cellphone.value
        }

        const response = await fetch(API_URL + '/users/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(country ? {...payload, addresses: [{
                zip: e.target.zip.value,
                street: e.target.address.value,
                city: e.target.city.value,
                state: e.target.state.value,
                country: country
              }]} : {...payload})
        })

        if (response.status === 200) {
            navigate('/users')
        }
    }

    useEffect(() => {
        fetchInitialData()
    }, [])

  return (
    <form onSubmit={ (e) => handleSubmit(e)}>
      <SideMenu>
        <ContainerCard title="Cliente" subtitle="Crear un nuevo"
          action={
            <Button 
              type="submit"
              className="btn btn-primary">Guardar</Button>
          }>
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