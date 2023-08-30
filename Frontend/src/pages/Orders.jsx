import ContainerCard from "../components/ContainerCard"
import SideMenu from "../components/SideMenu"

import { API_URL } from "../App"
import { useState, useEffect } from "react"
import { PencilIcon, TrashIcon } from "@heroicons/react/solid"
import { 
    Badge, 
    Button, 
    Icon, 
    Select, 
    SelectItem, 
    Table, 
    TableBody, 
    TableCell, 
    TableHead, 
    TableHeaderCell, 
    TableRow 
} from "@tremor/react"
import { anulateOrder } from "../components/services/orders"

function Orders() {
    const [orders, setOrders] = useState({ items: [] })
    const fetchOrders = async () => {
        const response = await fetch(`${API_URL}/orders/all`, {
            method: "GET",
            headers: { "Content-Type": "application/json" }
        })

        const data = await response.json()
        setOrders(data)
    }

    const deleteOrder = async (id) => {
        if (confirm("¿Esta seguro que desea eliminar esta orden?")) {
            let response = await anulateOrder(id)

            if (response.status === 200) {
                alert("Orden eliminada con exito")
                fetchOrders()
            } else {
                alert("Error al eliminar la orden")
            }
        }
    }


    useEffect(() => {
        fetchOrders()
    }, [])

    return (
        <SideMenu>
            <ContainerCard title="Ordenes" subtitle="Administrador de" action={
                <div className="flex flex-row gap-2">
                    <Select placeholder="Filtrar por...">
                        <SelectItem>Pagadas</SelectItem>
                        <SelectItem>Pendientes</SelectItem>
                        <SelectItem>Canceladas</SelectItem>
                    </Select>
                    <Button onClick={() => navigate("/users/new/client")}>Nuevo Cliente</Button>
                </div>
            }>

                <Table>
                    <TableHead>
                        <TableHeaderCell>Orden</TableHeaderCell>
                        <TableHeaderCell>Origen</TableHeaderCell>
                        <TableHeaderCell>Fecha de creacion</TableHeaderCell>
                        <TableHeaderCell>Fecha de pago</TableHeaderCell>
                        <TableHeaderCell>IP</TableHeaderCell>
                        <TableHeaderCell>Estado</TableHeaderCell>
                    </TableHead>
                    <TableBody>
                        {orders.items.map((order) => (
                            <TableRow>
                                <TableCell><small>{order.id}</small></TableCell>
                                <TableCell>{order.origin}</TableCell>
                                <TableCell>{order.createdAt}</TableCell>
                                <TableCell>{order.payedAt}</TableCell>
                                <TableCell>{order.placedIp}</TableCell>
                                <TableCell><Badge>{order.status}</Badge></TableCell>
                                <TableCell>
                                    <Icon 
                                        className="cursor-pointer text-red-500"
                                        onClick={ (e) => { deleteOrder(order.id) }}
                                        icon={TrashIcon} />
                                    <Icon icon={PencilIcon} className="text-blue-500" />
                                </TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            </ContainerCard>

            
        </SideMenu>
    )
}

export default Orders