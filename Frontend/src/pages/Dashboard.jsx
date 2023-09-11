import {
  Grid,
  Col,
  Flex,
  Card,
  Metric,
  Text,
  Icon,
  Title,
  Table,
  TableHead,
  TableRow,
  TableHeaderCell,
  TableBody,
  TableCell,
  Badge,
  Divider,
  Button,
  List,
  ListItem
  , DonutChart, AreaChart, Select, SelectItem
} from '@tremor/react'

import { StatusOnlineIcon, CashIcon, CalculatorIcon, CreditCardIcon, CurrencyDollarIcon } from '@heroicons/react/outline'
import { useEffect, useState } from 'react'
import { GlobeIcon, PlusIcon } from '@heroicons/react/solid'
import { useNavigate } from 'react-router-dom'
import SideMenu from '../components/SideMenu'
import { fetchDashboardStats } from '../services/dashboard'
import { currencyFormatter } from '../helpers/dateFormatter'
import { toast } from 'react-toastify'
import { request } from '../services/request'

function Dashboard () {
  const [salesByMonth, setSalesByMonth] = useState([])
  const [salesByProduct, setSalesByProduct] = useState([])
  const [salesThisMonth, setSalesThisMonth] = useState(0)
  const [salesMonthTitle, setSalesMonthTitle] = useState('')
  const [lastSales, setLastSales] = useState([])
  const [salesBySource, setSalesBySource] = useState([])
  const [expensesThisMonth, setExpensesThisMonth] = useState(0)
  const [constMonth, setConstMonth] = useState({ short: new Date().toLocaleString('default', { month: '2-digit' }).toLowerCase() })
  const [costs, setCosts] = useState([])
  const navigate = useNavigate()

  const fetchOrderStats = async () => {
    const response = await fetchDashboardStats()
    const data = response.data
    setSalesByMonth(data.salesByMonth)
    setSalesByProduct(data.salesByProduct)
    setSalesThisMonth(data.salesThisMonth)
    setSalesMonthTitle(data.salesMonthTitle)
    setLastSales(data.lastSales)
    setSalesBySource(data.salesBySource)
    setExpensesThisMonth(data.expensesThisMonth)
  }

  const fetchCostsByMonth = async () => {
    const year = new Date().getFullYear()
    try {
      const response = await request.get('/finance/costs/date/' + year + '/' + constMonth.short)
      const data = response.data
      setCosts(data)
    } catch (error) {
      toast('Error al obtener los costos')
    }
  }

  useEffect(() => {
    fetchOrderStats()
  }, [])

  useEffect(() => {
    fetchCostsByMonth()
  }, [constMonth])

  const valueFormatter = (number) => `$ ${Intl.NumberFormat('us').format(number).toString()}`
  const dataFormatter = (number) => {
    return '$ ' + Intl.NumberFormat('us').format(number).toString()
  }

  return (
    <>
      <SideMenu>
        <Grid numItems={1} numItemsSm={1} numItemsLg={3} className='gap-2'>
          <Col numColSpan={1} numColSpanLg={3}>
            <Card decoration='top' color='purple'>
              <Text>Ultimas</Text>
              <Metric>Ordenes</Metric>

              <Title>Ordenes pendientes por procesar, validar o enviar.</Title>
              <Table className='mt-5'>
                <TableHead>
                  <TableRow>
                    <TableHeaderCell>Cliente</TableHeaderCell>
                    <TableHeaderCell>Transaccion</TableHeaderCell>
                    <TableHeaderCell>Contacto</TableHeaderCell>
                    <TableHeaderCell>Status</TableHeaderCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  <TableRow>
                    <TableCell>Alain Berset</TableCell>
                    <TableCell>President</TableCell>
                    <TableCell>Home Affairs</TableCell>
                    <TableCell>
                      <Badge color='emerald' icon={StatusOnlineIcon}>
                        PENDING
                      </Badge>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </Card>
          </Col>
          <Card>
            <Text>Finanazas del mes</Text>
            <Metric>{salesMonthTitle}</Metric>

            <Divider className='mt-4' />
            <Flex className='space-x-6'>
              <Icon icon={CurrencyDollarIcon} color='green' variant='solid' tooltip='Sum of Sales' size='sm' />
              <div className='w-full'>
                <Text color='green'>Ventas</Text>
                <Metric color='green'>{dataFormatter(salesThisMonth)}</Metric>
              </div>
            </Flex>
            <Flex className='space-x-6'>
              <Icon icon={CalculatorIcon} color='rose' variant='solid' tooltip='Sum of Sales' size='sm' />
              <div className='w-full'>

                <Text color='red'>Gastos</Text>
                <Metric color='red'>{currencyFormatter(expensesThisMonth)}</Metric>
              </div>

              <Button
                onClick={() => navigate('/add-cost')}
                color='rose' icon={PlusIcon}
              />
            </Flex>
            <Divider className='mt-4' />
            {salesBySource.map((source, index) => {
              let icon = null
              if (source.name === 'posCash') {
                icon = <Icon icon={CashIcon} color='green' variant='solid' tooltip='Sum of Sales' size='sm' />
              } else if (source.name === 'posCard') {
                icon = <Icon icon={CreditCardIcon} color='green' variant='solid' tooltip='Sum of Sales' size='sm' />
              } else if (source.name === 'web') {
                icon = <Icon icon={GlobeIcon} color='green' variant='solid' tooltip='Sum of Sales' size='sm' />
              }

              return (
                <Flex className='space-x-6' key={index}>
                  {icon}
                  <div className='w-full'>
                    <Text color='green'>Ventas {source.name}</Text>
                    <Metric color='green'>{dataFormatter(source.value)}</Metric>
                  </div>
                </Flex>
              )
            })}

            <Divider className='mt-4' />
            <Button className='w-full mb-2' color='green' size='xl' onClick={() => navigate('/pos')}>
              Ir al modulo POS
            </Button>
            <Button onClick={(e) => navigate('/orders')} className='w-full' color='green' variant='secondary' size='xl'>Ir al modulo de transacciones</Button>
            <Divider className='mt-4' />
            <Button className='w-full mb-2' color='blue' size='xl' onClick={() => navigate('/products/new')}>
              Crear un nuevo producto
            </Button>
            <Button className='w-full mb-2' color='blue' variant='secondary' size='xl' onClick={() => navigate('/products')}>
              Gestionar el catalogo
            </Button>
            <Divider className='mt-4' />
            <Button className='w-full mb-2' color='blue' size='xl' onClick={() => navigate('/users/new/client')}>
              Crear un nuevo cliente
            </Button>
            <Button className='w-full mb-2' color='blue' variant='secondary' size='xl' onClick={() => navigate('/users/new/provider')}>
              Crear un nuevo proveedor
            </Button>
            <Button className='w-full mb-2' color='blue' variant='secondary' size='xl' onClick={() => navigate('/users/new/employee')}>
              Crear un nuevo empleado
            </Button>
          </Card>
          <Card>
            <Text>por producto</Text>
            <Metric>Ventas</Metric>
            <Divider className='mt-4' />
            <DonutChart
              className='mt-6'
              data={salesByProduct}
              category='value'
              index='name'
              valueFormatter={valueFormatter}
              colors={['slate', 'violet', 'indigo', 'rose', 'cyan', 'amber']}
            />
            <Table className='mt-5'>
              <TableHead>
                <TableRow>
                  <TableHeaderCell>TX</TableHeaderCell>
                  <TableHeaderCell>Costo</TableHeaderCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {lastSales.map((sale, index) => {
                  return (
                    <TableRow key={'sales_' + index}>
                      <TableCell>{sale.payedAt}</TableCell>
                      <TableCell>{dataFormatter(sale.items.reduce((acc, item) => acc + (item.price * item.quantity), 0))}</TableCell>
                    </TableRow>
                  )
                })}
              </TableBody>
            </Table>

            <Button className='w-full mt-4' onClick={(e) => navigate('/orders')} variant='secondary'>Ver todas las transacciones</Button>
          </Card>
          <Col>
            <Card>
              <Text>Ingresos/Egresos</Text>
              <Metric>Finanzas Anuales</Metric>
              <Divider className='mt-4' />
              <AreaChart
                className='h-72 mt-4'
                data={salesByMonth}
                index='name'
                showYAxis={false}
                categories={['cost', 'sales']}
                colors={['rose', 'green']}
                valueFormatter={dataFormatter}
              />
              <Table fontSize='xs' className='mt-0'>
                <TableHead>
                  <TableHeaderCell>Mes</TableHeaderCell>
                  <TableHeaderCell>Ventas</TableHeaderCell>
                  <TableHeaderCell>Costos</TableHeaderCell>
                  <TableHeaderCell>Utilidad</TableHeaderCell>
                </TableHead>
                <TableBody>
                  {salesByMonth.map((month, index) => {
                    return (
                      <TableRow key={'d_' + index}>
                        <TableCell><strong>{month.name}</strong></TableCell>
                        <TableCell>
                          <div>
                            <small>({month.value})</small><br />
                            <small> {dataFormatter(month.sales)}</small>
                          </div>
                        </TableCell>
                        <TableCell><small>{dataFormatter(month.cost * -1)}</small></TableCell>
                        <TableCell><small>{dataFormatter(month.sales - month.cost)}</small></TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>
              <List className='mt-5'>
                <ListItem>
                  <span>Ventas Anuales</span>
                  <span>{dataFormatter(salesByMonth.reduce((acc, month) => acc + month.sales, 0))}</span>
                </ListItem>
                <ListItem>
                  <span>Costos Anuales</span>
                  <span>{dataFormatter(salesByMonth.reduce((acc, month) => acc + month.cost, 0) * -1)}</span>
                </ListItem>
                <ListItem>
                  <span>Utilidad Anual</span>
                  <span>{dataFormatter(salesByMonth.reduce((acc, month) => acc + (month.sales - month.cost), 0))}</span>
                </ListItem>
                <ListItem>
                  <span>Total Ventas Anuales</span>
                  <span>{salesByMonth.reduce((acc, month) => acc + month.value, 0)}</span>
                </ListItem>
              </List>
            </Card>
          </Col>

          <Col numColSpan={1} numColSpanLg={2}>
            <Card>
              <Flex>
                <div className='flex-1 w-full'>
                  <Text>Explora tus</Text>
                  <Metric>Gastos del mes</Metric>
                </div>
                <div className='flex-none' />
                <Select value={constMonth.short} onChange={(e) => setConstMonth({ short: e })} className='w-20'>
                  <SelectItem value='01'>Enero</SelectItem>
                  <SelectItem value='02'>Febrero</SelectItem>
                  <SelectItem value='03'>Marzo</SelectItem>
                  <SelectItem value='04'>Abril</SelectItem>
                  <SelectItem value='05'>Mayo</SelectItem>
                  <SelectItem value='06'>Junio</SelectItem>
                  <SelectItem value='07'>Julio</SelectItem>
                  <SelectItem value='08'>Agosto</SelectItem>
                  <SelectItem value='09'>Septiembre</SelectItem>
                  <SelectItem value='10'>Octubre</SelectItem>
                  <SelectItem value='11'>Noviembre</SelectItem>
                  <SelectItem value='12'>Diciembre</SelectItem>
                </Select>
              </Flex>

              <List className='mt-4'>
                {costs.map((cost, index) => {
                  return (
                    <ListItem key={'cost_' + cost.id}>
                      <span>{cost.name} ... <Badge size='xs'>{cost.type}</Badge></span>
                      <span>{currencyFormatter(cost.amount * -1)}</span>
                    </ListItem>
                  )
                })}
              </List>
            </Card>
          </Col>

          {/* <Card>
            <Text>Proximas</Text>
            <Metric>Deudadas automatizadas</Metric>
              </Card> */}
        </Grid>
      </SideMenu>
    </>
  )
}

export default Dashboard
