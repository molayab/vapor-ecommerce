import ContainerCard from '../components/ContainerCard'
import SideMenu from '../components/SideMenu'
import { useState, useEffect } from 'react'
import { TrashIcon } from '@heroicons/react/solid'
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
  TextInput,
  Metric,
  List,
  ListItem,
  Title,
  Subtitle,
  Grid,
  Divider
} from '@tremor/react'
import { anulateOrder, fetchOrders } from '../services/orders'
import { toast } from 'react-toastify'
import { currencyFormatter, dateTimeFormatter } from '../helpers/dateFormatter'
import Loader from '../components/Loader'
import { request } from '../services/request'

const { confirm } = window

function Orders () {
  const [page, setPage] = useState(1)
  const [orders, setOrders] = useState({ items: [] })
  const [isLoading, setIsLoading] = useState(false)
  const [metadata, setMetadata] = useState({})
  const fetchOrdersX = async (page) => {
    setIsLoading(true)
    const response = await fetchOrders(page)

    if (response.status !== 200) {
      toast('Error al obtener las ordenes')
      return
    }

    const data = response.data
    setOrders(data)
    setIsLoading(false)
  }

  const nextPage = () => {
    setPage((old) => old + 1)
  }

  const prevPage = () => {
    setPage((old) => old - 1)
  }

  const fetchOrdersMetadata = async () => {
    setIsLoading(true)
    const response = await request.get('/orders/all/metadata')

    if (response.status !== 200) {
      toast('Error al obtener los metadatos de las ordenes')
      return
    }

    const data = response.data
    setMetadata(data)
    setIsLoading(false)
  }

  const deleteOrder = async (id) => {
    if (confirm('¿Esta seguro que desea anular esta orden?')) {
      const response = await anulateOrder(id)

      if (response.status === 200) {
        toast('Orden anulada con exito')
        fetchOrdersX(page)
      } else {
        toast('Error al anular la orden')
      }
    }
  }

  useEffect(() => {
    fetchOrdersX(page)
  }, [page])

  useEffect(() => {
    fetchOrdersMetadata()
  }, [])

  function formatISODateToHumanReadable (isoDate) {
    const options = { year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric' }
    const date = new Date(isoDate)
    return date.toLocaleString('es-US', options)
  }

  if (isLoading) return (<Loader />)
  return (
    <SideMenu>
      <ContainerCard
        title='Ordenes' subtitle='Administrador de' action={
          <div className='flex flex-row gap-2'>
            <Select placeholder='Filtrar por...'>
              <SelectItem>Pagadas</SelectItem>
              <SelectItem>Pendientes</SelectItem>
              <SelectItem>Canceladas</SelectItem>
            </Select>
          </div>
            }
      >
        <Divider />
        <Grid numItems={2} numItemsLg={4} numItemsMd={2} className='gap-1 mt-4'>
          <div>
            <Subtitle>Total ordenes</Subtitle>
            <Metric
              color='gray'
            >{metadata.total}
            </Metric>
          </div>
          <div>
            <Subtitle>Total ordenes pagadas</Subtitle>
            <Metric
              color='gray'
            >{metadata.paid}
            </Metric>
          </div>
          <div>
            <Subtitle>Total ordenes canceladas</Subtitle>
            <Metric
              color='rose'
            >{metadata.canceled}
            </Metric>
          </div>
          <div>
            <Subtitle>Total ordenes en proceso</Subtitle>
            <Metric
              color='orange'
            >{metadata.pending}
            </Metric>
          </div>
          <div>
            <Subtitle>Total de dinero recaudado /año</Subtitle>
            <Metric
              color='gray'
            >{currencyFormatter(metadata.totalSales)}<Badge color='clear'>/año</Badge>
            </Metric>
          </div>
          <div>
            <Subtitle>Total ingresos brutos</Subtitle>
            <Metric
              color='green'
            >{currencyFormatter(metadata.totalSales - metadata.totalTaxes)}<Badge color='clear'>/año</Badge>
            </Metric>
          </div>
          <div>
            <Subtitle>Beneficio total</Subtitle>
            <Metric
              color='green'
            >{currencyFormatter(metadata.totalRevenue)}<Badge color='clear'>/año</Badge>
            </Metric>
          </div>
          <div>
            <Subtitle>Total en impuestos</Subtitle>
            <Metric
              color='orange'
            >{currencyFormatter(metadata.totalTaxes)}<Badge color='clear'>/año</Badge>
            </Metric>
          </div>
        </Grid>
        <Divider />
        <Table>
          <TableHead>
            <TableHeaderCell>Orden</TableHeaderCell>
            <TableHeaderCell>Total</TableHeaderCell>
            <TableHeaderCell>Origen</TableHeaderCell>
            <TableHeaderCell>Estado</TableHeaderCell>
          </TableHead>
          <TableBody>
            {orders.items.map((order) => (
              <TableRow key={order.id} className='hover:bg-slate-800'>
                <TableCell>
                  <Title>{formatISODateToHumanReadable(order.payedAt)}</Title><br />
                  <Subtitle><small>{order.id}</small></Subtitle>
                  <small>{order.placedIp}</small>
                  <List>
                    {order.items.map((item) => (
                      <ListItem key={item.id}>
                        <span>{item.productVariant.product.title} / {item.productVariant.name} x {item.quantity}</span>
                        <span className='float-right'>{currencyFormatter((item.price * item.quantity))}</span>
                      </ListItem>
                    ))}
                  </List>
                </TableCell>
                <TableCell>
                  <Metric
                    color={order.status === 'paid' ? 'green' : 'red'}
                  >{currencyFormatter(order.items.reduce((acc, i) => acc + (i.price * i.quantity) + ((i.price * i.quantity) * order.tax), 0))}
                  </Metric>
                </TableCell>
                <TableCell>
                  <Badge color='gray'>{order.origin}</Badge><br />
                  <Badge
                    className='mt-2' color={
                    order.status === 'paid'
                      ? 'green'
                      : order.status === 'pending'
                        ? 'yellow'
                        : order.status === 'canceled' ? 'red' : 'gray'
                  }
                  >{order.status}
                  </Badge>
                </TableCell>
                <TableCell>
                  <b>Pagada:</b><br /> {dateTimeFormatter(order.payedAt)} <br />
                  <b>Creada:</b><br /> {dateTimeFormatter(order.createdAt)}
                </TableCell>
                <TableCell>
                  <Icon
                    className='cursor-pointer text-red-500'
                    onClick={(e) => { deleteOrder(order.id) }}
                    icon={TrashIcon}
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        <Flex justifyContent='end' className='space-x-2 pt-4 mt-8'>
          <Button size='xs' variant='secondary' onClick={prevPage} disabled={page === 1}>
            Anterior
          </Button>

          <TextInput size='xs' className='w-10' value={page} readOnly />

          <Button size='xs' variant='primary' onClick={nextPage} disabled={page === (orders.total / orders.per).toFixed()}>
            Siguiente
          </Button>
        </Flex>
      </ContainerCard>

    </SideMenu>
  )
}

export default Orders
