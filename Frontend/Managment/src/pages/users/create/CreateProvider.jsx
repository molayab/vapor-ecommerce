import SideMenu from "../../../components/SideMenu"
import ContainerCard from "../../../components/ContainerCard"
import { Grid, SearchSelect, SearchSelectItem, TextInput, Title, MultiSelect, MultiSelectItem, Select, SelectItem, Button, Text } from "@tremor/react"
import { useState, useEffect } from "react"
import { useNavigate } from "react-router-dom"
import { API_URL } from "../../../App"

function CreateProvider() {
    const [countries, setCountries] = useState([]);
    const [country, setCountry] = useState('');
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

        const payload = {
            name: e.target.name.value,
            email: e.target.email.value,
            nationalIdType: nationalIdType,
            nationalId: e.target.document.value,
            phone: e.target.telephone.value,
            cellphone: e.target.cellphone.value,
            addresses: [{
                zip: e.target.zip.value,
                street: e.target.address.value,
                city: e.target.city.value,
                state: e.target.state.value,
                country: country
            }]
        }

        console.log(payload)
        const response = await fetch(API_URL + '/users/create/provider', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        })

        if (response.status === 200) {
            navigate('/users')
        }
    }

    useEffect(() => {
        fetchInitialData()
    }, [])

    return (
        <SideMenu>
            <form onSubmit={ (e) => handleSubmit(e) } className="mt-4">
                <ContainerCard title="Proveedor" subtitle="Crear un nuevo" action={
                    <Button className="btn btn-primary">Guardar</Button>
                }>
                
                    <Title className="py-4">Datos basicos</Title>
                    <Grid numItems={2} className="gap-1">
                        <TextInput name="name" placeholder="Nombre Completo" />
                        <TextInput name="email" placeholder="Correo" aria-required />
                        <Select placeholder="Tipo de documento" aria-required onValueChange={setNationalIdType} value={nationalIdType}>
                            { nationalIds.map((nationalId) => (
                                <SelectItem key={nationalId.id} value={nationalId.id}>{nationalId.name}</SelectItem>
                            )) }
                        </Select>
                        <TextInput name="document" placeholder="Numero de documento" />
                    </Grid>

                    <Title className="py-4">Datos de contacto</Title>
                    <Grid numItems={2} className="gap-1">
                        <TextInput name="telephone" placeholder="Telefono" />
                        <TextInput name="cellphone" placeholder="Celular" />
                        <TextInput name="zip" placeholder="ZIP" />
                        <TextInput name="address" placeholder="Direccion" />
                        <TextInput name="city" placeholder="Ciudad" />
                        <TextInput name="state" placeholder="Estado / Departamento" />
                        <SearchSelect placeholder="Pais" aria-required onValueChange={setCountry} value={country}>
                            { countries.map((country) => (
                                <SearchSelectItem key={country.code} value={country.code}>{country.name}</SearchSelectItem>
                            )) }
                        </SearchSelect>
                    </Grid>

                    <Text className="pt-8">
                        Al crear un empleado, este esta sujeto a los terminos y condiciones de la plataforma. La ley de proteccion de datos personales y la ley de habeas data.
                    </Text>
                </ContainerCard>
            </form>
        </SideMenu>
    )
}

export default CreateProvider