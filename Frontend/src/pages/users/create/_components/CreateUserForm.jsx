import { Grid, SearchSelect, SearchSelectItem, Select, SelectItem, Text, TextInput, Title } from '@tremor/react'

export default function CreateUserForm({ nationalIds, setNationalIdType, nationalIdType, countries, setCountry, country}) {
    return (
        <>
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
        </>
    )
}