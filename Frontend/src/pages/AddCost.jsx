import { DatePicker, Select, SelectItem, TextInput } from "@tremor/react"
import ContainerCard from "../components/ContainerCard"
import SideMenu from "../components/SideMenu"

function AddCost() {
    return (
        <SideMenu>
            <ContainerCard title="Agregar Costo" subtitle="Egresos de la tienda">
                <Select placeholder="Seleccionar tipo de costo">
                    <SelectItem>Fijo</SelectItem>
                    <SelectItem>Variable</SelectItem>
                </Select>

                <Select placeholder="Seleccionar periodicidad">
                    <SelectItem>Pago unico</SelectItem>
                    <SelectItem>Diario</SelectItem>
                    <SelectItem>Semanal</SelectItem>
                    <SelectItem>Quincenal</SelectItem>
                    <SelectItem>Mensual</SelectItem>
                    <SelectItem>Bimestral</SelectItem>
                    <SelectItem>Trimestral</SelectItem>
                    <SelectItem>Semestral</SelectItem>
                    <SelectItem>Anual</SelectItem>
                </Select>

                <TextInput placeholder="Nombre del costo" />
                <TextInput placeholder="Descripcion del costo" />

                <Select placeholder="Seleccionar moneda">
                    <SelectItem>COP</SelectItem>
                    <SelectItem>USD</SelectItem>
                </Select>

                <TextInput placeholder="Valor del costo" />
                <DatePicker placeholder="Fecha de inicio" />

            </ContainerCard>
        </SideMenu>
    )
}

export default AddCost