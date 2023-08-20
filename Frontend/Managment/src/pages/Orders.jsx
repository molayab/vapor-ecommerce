import ContainerCard from "../components/ContainerCard"
import SideMenu from "../components/SideMenu"
import { API_URL } from "../App"
import { useState, useEffect } from "react"
import { Badge, Button, Icon, Select, SelectItem, Table, TableBody, TableCell, TableHead, TableHeaderCell, TableRow } from "@tremor/react"
import { PencilIcon, TrashIcon } from "@heroicons/react/solid"
import { isFeatureEnabled } from "../App"

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
                                    <Icon icon={TrashIcon} className="text-red-500" />
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