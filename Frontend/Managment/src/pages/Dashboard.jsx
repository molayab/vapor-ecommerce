import { Grid, Col, Flex, Card, Metric, Text, Icon, Title, Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell, Badge, Divider } from "@tremor/react";
import { DonutChart } from "@tremor/react";
import { StatusOnlineIcon } from "@heroicons/react/outline";
import Header from "../components/Header";
import SideMenu from "../components/SideMenu";
import { AreaChart } from "@tremor/react";
import { CashIcon, CalculatorIcon, CreditCardIcon, CurrencyDollarIcon } from "@heroicons/react/outline";

function Dashboard() {
  const cities = [
    {
      name: "New York",
      sales: 9800,
    },
    {
      name: "London",
      sales: 4567,
    },
    {
      name: "Hong Kong",
      sales: 3908,
    },
    {
      name: "San Francisco",
      sales: 2400,
    },
    {
      name: "Singapore",
      sales: 1908,
    },
    {
      name: "Zurich",
      sales: 1398,
    },
  ];
  
  const valueFormatter = (number) => `$ ${Intl.NumberFormat("us").format(number).toString()}`;

  const chartdata = [
    {
      date: "Jan 22",
      x: 2890,
      y: 2338,
    },
    {
      date: "Feb 22",
      x: 2756,
      y: 2103,
    },
    {
      date: "Mar 22",
      x: 3322,
      y: 2194,
    },
    {
      date: "Apr 22",
      x: 3470,
      y: 2108,
    },
    {
      date: "May 22",
      x: 3475,
      y: 1812,
    },
    {
      date: "Jun 22",
      x: 3129,
      y: 1726,
    },
  ];
  
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
              data={cities}
              category="sales"
              index="name"
              valueFormatter={valueFormatter}
              colors={["slate", "violet", "indigo", "rose", "cyan", "amber"]}
            />
              <Table className="mt-5">
                <TableHead>
                  <TableRow>
                    <TableHeaderCell>Cliente</TableHeaderCell>
                    <TableHeaderCell>Transaccion</TableHeaderCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  <TableRow>
                    <TableCell>Alain Berset</TableCell>
                    <TableCell>President</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell>Alain Berset</TableCell>
                    <TableCell>President</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell>Alain Berset</TableCell>
                    <TableCell>President</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell>Alain Berset</TableCell>
                    <TableCell>President</TableCell>
                  </TableRow>
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
                data={chartdata}
                index="date"
                categories={["x", "y"]}
                colors={["rose", "green"]}
                valueFormatter={dataFormatter}
              />
              <Table className="mt-5">
                <TableHead>
                  <TableRow>
                    <TableHeaderCell>Cliente</TableHeaderCell>
                    <TableHeaderCell>Transaccion</TableHeaderCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  <TableRow>
                    <TableCell>Alain Berset</TableCell>
                    <TableCell>President</TableCell>
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
            <Metric>Agosto</Metric>

            <Divider className="mt-4" />
            <Flex className="space-x-6">
              <Icon icon={CurrencyDollarIcon} color="green" variant="solid" tooltip="Sum of Sales" size="sm" />
              <div>
                <Text color="green">Ventas</Text>
                <Metric color="green">$ 34,743</Metric>
              </div>
            </Flex>
            <Flex className="space-x-6">
              <Icon icon={CalculatorIcon} color="rose" variant="solid" tooltip="Sum of Sales" size="sm" />
              <div>
                <Text color="red">Gastos</Text>
                <Metric color="red">$ 44,300,000.00</Metric>
              </div>
            </Flex>
            <Divider className="mt-4" />
            <Flex className="space-x-6">
              <Icon icon={CreditCardIcon} color="green" variant="solid" tooltip="Sum of Sales" size="sm" />
              <div>
                <Text color="green">Ventas eCommerce</Text>
                <Metric color="green">$ 34,743</Metric>
              </div>
            </Flex>
            <Flex className="space-x-6">
              <Icon icon={CashIcon} color="green" variant="solid" tooltip="Sum of Sales" size="sm" />
              <div>
                <Text color="green">Ventas POS</Text>
                <Metric color="green">$ 34,743</Metric>
              </div>
            </Flex>
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