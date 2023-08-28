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
} from "@tremor/react"

import { DonutChart } from "@tremor/react"
import { StatusOnlineIcon } from "@heroicons/react/outline"
import { AreaChart } from "@tremor/react"
import { CashIcon, CalculatorIcon, CreditCardIcon, CurrencyDollarIcon } from "@heroicons/react/outline"
import { useEffect, useState } from "react"
import { API_URL } from "../App"
import { GlobeIcon, PlusIcon } from "@heroicons/react/solid"
import { useNavigate } from "react-router-dom"
import SideMenu from "../components/SideMenu"

function Dashboard() {
  const [salesByMonth, setSalesByMonth] = useState([])
  const [salesByProduct, setSalesByProduct] = useState([])
  const [salesThisMonth, setSalesThisMonth] = useState(0)
  const [salesMonthTitle, setSalesMonthTitle] = useState("")
  const [lastSales, setLastSales] = useState([])
  const [salesBySource, setSalesBySource] = useState([])
  const navigate = useNavigate()

  const fetchOrderStats = async () => {
    const response = await fetch(`${API_URL}/dashboard/stats`, {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    })

    const data = await response.json()
    setSalesByMonth(data.salesByMonth)
    setSalesByProduct(data.salesByProduct)
    setSalesThisMonth(data.salesThisMonth)
    setSalesMonthTitle(data.salesMonthTitle)
    setLastSales(data.lastSales)
    setSalesBySource(data.salesBySource)
  }

  useEffect(() => {
    fetchOrderStats()
  }, [])
  
  const valueFormatter = (number) => `$ ${Intl.NumberFormat("us").format(number).toString()}`;
  const dataFormatter = (number) => {
    return "$ " + Intl.NumberFormat("us").format(number).toString();
  };

  return (
    <>
      <SideMenu>
        <Grid numItems={1} numItemsSm={1} numItemsLg={3} className="gap-2">
          <Col numColSpan={1} numColSpanLg={3}>
            <Card decoration="top" color="purple">
              <Text>Ultimas</Text>
              <Metric>Ordenes</Metric>

              <Title>Ordenes pendientes por procesar, validar o enviar.</Title>
              <Table className="mt-5">
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
                    <TableCell><Badge color="emerald" icon={StatusOnlineIcon}>
                      PENDING
                    </Badge></TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </Card>
          </Col>
          <Card>
            <Text>Finanazas del mes</Text>
            <Metric>{ salesMonthTitle }</Metric>

            <Divider className="mt-4" />
            <Flex className="space-x-6">
              <Icon icon={CurrencyDollarIcon} color="green" variant="solid" tooltip="Sum of Sales" size="sm" />
              <div className="w-full">
                <Text color="green">Ventas</Text>
                <Metric color="green">{ dataFormatter(salesThisMonth) }</Metric>
              </div>
            </Flex>
            <Flex className="space-x-6">
              <Icon icon={CalculatorIcon} color="rose" variant="solid" tooltip="Sum of Sales" size="sm" />
              <div className="w-full">
                
                <Text color="red">Gastos</Text>
                <Metric color="red">$ 0.00</Metric>
              </div>

              <Button color="rose" icon={PlusIcon} />
            </Flex>
            <Divider className="mt-4" />
            {salesBySource.map((source, index) => {
              let icon = null;
              if (source.name === "posCash") {
                icon = <Icon icon={CashIcon} color="green" variant="solid" tooltip="Sum of Sales" size="sm" />
              } else if (source.name === "posCard") {
                icon = <Icon icon={CreditCardIcon} color="green" variant="solid" tooltip="Sum of Sales" size="sm" />
              } else if (source.name === "web") {
                icon = <Icon icon={GlobeIcon} color="green" variant="solid" tooltip="Sum of Sales" size="sm" />
              }

              return (
                <Flex className="space-x-6" key={index}>
                  { icon }
                  <div className="w-full">
                    <Text color="green">Ventas { source.name }</Text>
                    <Metric color="green">{ dataFormatter(source.value) }</Metric>
                  </div>
                </Flex>
              )
            })}

            <Divider className="mt-4" />
            <Button className="w-full mb-2" color="green" size="xl" onClick={() => navigate("/pos")}>
              Ir al modulo POS
            </Button>
            <Button className="w-full" color="green" variant="secondary" size="xl">Ir al modulo de ventas</Button>
            <Divider className="mt-4" />
            <Button className="w-full mb-2" color="blue" size="xl" onClick={() => navigate("/products/new")}>
              Crear un nuevo producto
            </Button>
            <Button className="w-full mb-2" color="blue" variant="secondary" size="xl" onClick={() => navigate("/products")}>
              Gestionar el catalogo
            </Button>
            <Divider className="mt-4" />
            <Button className="w-full mb-2" color="blue" size="xl" onClick={() => navigate("/users/new/client")}>
              Crear un nuevo cliente
            </Button>
            <Button className="w-full mb-2" color="blue" variant="secondary" size="xl" onClick={() => navigate("/users/new/provider")}>
              Crear un nuevo proveedor
            </Button>
            <Button className="w-full mb-2" color="blue" variant="secondary" size="xl" onClick={() => navigate("/users/new/employee")}>
              Crear un nuevo empleado
            </Button>
          </Card>
          <Card>
            <Text>por producto</Text>
            <Metric>Ventas</Metric>
            <Divider className="mt-4" />
            <DonutChart
              className="mt-6"
              data={salesByProduct}
              category="value"
              index="name"
              valueFormatter={valueFormatter}
              colors={["slate", "violet", "indigo", "rose", "cyan", "amber"]}
            />
              <Table className="mt-5">
                <TableHead>
                  <TableRow>
                    <TableHeaderCell>TX</TableHeaderCell>
                    <TableHeaderCell>Costo</TableHeaderCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {lastSales.map((sale) => {
                    return (
                      <TableRow>
                        <TableCell>{ sale.payedAt }</TableCell>
                        <TableCell>{ dataFormatter(sale.items.reduce((acc, item) => acc + (item.total * item.quantity), 0)) }</TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>

              <Button className="w-full my-2">Ver todas las ventas</Button>
              <Button className="w-full" variant="secondary">Ver todas las transacciones</Button>
          </Card>
          <Col>
            <Card>
              <Text>Ingresos/Egresos</Text>
              <Metric>Finanzas Anuales</Metric>
              <Divider className="mt-4" />
              <AreaChart
                className="h-72 mt-4"
                data={salesByMonth}
                index="name"
                showYAxis={false}
                categories={["cost", "sales"]}
                colors={["rose", "green"]}
                valueFormatter={dataFormatter}
              />
              <Table fontSize="xs" className="mt-0">
                <TableHead>
                  <TableHeaderCell>Mes</TableHeaderCell>
                  <TableHeaderCell>Ventas</TableHeaderCell>
                  <TableHeaderCell>Costos</TableHeaderCell>
                  <TableHeaderCell>Utilidad</TableHeaderCell>
                </TableHead>
                <TableBody>
                {salesByMonth.map((month) => {
                  return (
                    <TableRow>
                      <TableCell><strong>{ month.name }</strong></TableCell>
                      <TableCell>
                        <div>
                          <small>({ month.value })</small><br />
                          <small> { dataFormatter(month.sales) }</small>
                        </div>
                      </TableCell>
                      <TableCell><small>{ dataFormatter(month.cost * -1) }</small></TableCell>
                      <TableCell><small>{ dataFormatter(month.sales - month.cost) }</small></TableCell>
                    </TableRow>
                  )
                })}
                </TableBody>
              </Table>
              <List className="mt-5">
                <ListItem>
                    <span>Ventas Anuales</span>
                    <span>{ dataFormatter(salesByMonth.reduce((acc, month) => acc + month.sales, 0)) }</span>
                  </ListItem>
                  <ListItem>
                    <span>Costos Anuales</span>
                    <span>{ dataFormatter(salesByMonth.reduce((acc, month) => acc + month.cost, 0) * -1) }</span>
                  </ListItem>
                  <ListItem>
                    <span>Utilidad Anual</span>
                    <span>{ dataFormatter(salesByMonth.reduce((acc, month) => acc + (month.sales - month.cost), 0)) }</span>
                  </ListItem>
                  <ListItem>
                    <span>Total Ventas Anuales</span>
                    <span>{ salesByMonth.reduce((acc, month) => acc + month.value, 0) }</span>
                  </ListItem>
              </List>
            </Card>
          </Col>
          
          <Col numColSpan={1} numColSpanLg={2}>
            <Card>
              <Text>Registrados recientemente</Text>
              <Metric>Clientes</Metric>
            </Card>
          </Col>
          
          <Card>
            <Text>Proximas</Text>
            <Metric>Deudadas automatizadas</Metric>
          </Card>
        </Grid>
      </SideMenu>
    </>
  );
}

export default Dashboard;