import { Grid, Col, Flex, Card, Metric, Text, Icon, Title, Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell, Badge, Divider, Subtitle } from "@tremor/react";
import { DonutChart } from "@tremor/react";
import { StatusOnlineIcon } from "@heroicons/react/outline";
import SideMenu from "../components/SideMenu";
import { AreaChart } from "@tremor/react";
import { CashIcon, CalculatorIcon, CreditCardIcon, CurrencyDollarIcon } from "@heroicons/react/outline";
import { useEffect, useState } from "react";
import { API_URL } from "../App";
import { GlobeIcon } from "@heroicons/react/solid";

function Dashboard() {
  const [salesByMonth, setSalesByMonth] = useState([])
  const [salesByProduct, setSalesByProduct] = useState([])
  const [salesThisMonth, setSalesThisMonth] = useState(0)
  const [salesMonthTitle, setSalesMonthTitle] = useState("")
  const [lastSales, setLastSales] = useState([])
  const [salesBySource, setSalesBySource] = useState([])

  const fetchOrderStats = async () => {
    const response = await fetch(`${API_URL}/orders/stats`, {
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
            <Card>
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
                        <TableCell>{ sale.items.reduce((acc, item) => acc + (item.total * item.quantity), 0) }</TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>
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
                categories={["x", "sales"]}
                colors={["rose", "green"]}
                valueFormatter={dataFormatter}
              />
              <Table className="mt-5">
                <TableBody>
                  <TableRow>
                    <TableCell>Ventas Anuales</TableCell>
                    <TableCell>$ { salesByMonth.reduce((acc, month) => acc + month.sales, 0) }</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell>Alain Berset</TableCell>
                    <TableCell>President</TableCell>
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
                <Metric color="green">$ { salesThisMonth }</Metric>
              </div>
            </Flex>
            <Flex className="space-x-6">
              <Icon icon={CalculatorIcon} color="rose" variant="solid" tooltip="Sum of Sales" size="sm" />
              <div className="w-full">
                <Text color="red">Gastos</Text>
                <Metric color="red">$ 0.00</Metric>
              </div>
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
                    <Metric color="green">$ { source.value }</Metric>
                  </div>
                </Flex>
              )
            })}
          </Card>
          
          <Col numColSpan={1} numColSpanLg={3}>
            <Card>
              <Text>Title</Text>
              <Metric>KPI 5</Metric>
            </Card>
          </Col>
          
        </Grid>
      </SideMenu>
    </>
  );
}

export default Dashboard;