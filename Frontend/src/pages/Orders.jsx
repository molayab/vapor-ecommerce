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
    TableRow,
    Flex,
    TextInput
} from "@tremor/react"
import { anulateOrder } from "../components/services/orders"
import { toast } from "react-toastify"

function Orders() {
    const [page, setPage] = useState(1)
    const [orders, setOrders] = useState({ items: [] })
    const fetchOrders = async (page) => {
        const response = await fetch(`${API_URL}/orders/all?page=${page}`, {
            method: "GET",
            headers: { "Content-Type": "application/json" }
        })

        const data = await response.json()
        setOrders(data)
    }

    const nextPage = () => {
        setPage((old) => old + 1)
    }

    const prevPage = () => {
        setPage((old) => old - 1)
    }

    const deleteOrder = async (id) => {
        if (confirm("¿Esta seguro que desea eliminar esta orden?")) {
            let response = await anulateOrder(id)

            if (response.status === 200) {
                fetchOrders(page)
            } else {
                toast("Error al eliminar la orden")
            }
        }
    }

    useEffect(() => {
        fetchOrders(page)
    }, [page])

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

                <Flex justifyContent="end" className="space-x-2 pt-4 mt-8">
                    <Button size="xs" variant="secondary" onClick={prevPage} disabled={page === 1}>
                    Anterior
                    </Button>

                    <TextInput size="xs" className='w-10' value={page} readOnly />

                    <Button size="xs" variant="primary" onClick={nextPage} disabled={page === (orders.total / orders.per).toFixed()}>
                    Siguiente
                    </Button>
                </Flex>
            </ContainerCard>

            
        </SideMenu>
    )
}

export default Orders