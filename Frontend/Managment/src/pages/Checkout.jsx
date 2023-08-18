import SideMenu from "../components/SideMenu";
import { Button, Card, Flex, Grid, Metric, NumberInput, Subtitle, Tab, TabGroup, TabList, Table, TableBody, TableHead, TableHeaderCell, TableRow, Text, Title } from "@tremor/react";
import { useState } from "react";
import { API_URL } from "../App";

export function Checkout({ checkoutList }) {
    const [input, setInput] = useState('0')
    const [mode, setMode] = useState('posCash')

    const checkout = async () => {
        console.log('checkout')

        let response = await fetch(API_URL + '/orders/checkout/' + mode, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                shippingAddressId: null,
                billingAddressId: null,
                items: checkoutList.map((product) => ({
                    productVariantId: product.id,
                    quantity: product.quantity,
                    price: product.salePrice,
                    discount: 0,
                    tax: product.tax
            }))})
        })

        let data = await response.json()
        console.log(data)

        if (data.id) {
            alert('Orden creada con exito')
        } else {
            alert('Error al crear la orden')
        }
    }

    const onNumberPadClick = (value) => {
        if (value === 'DEL') {
            setInput(input.slice(0, -1))
        } else if (value === 'ENTER') {
            setInput('0')
        } else {
            if (input === '0') {
                setInput(value.toString())
            } else {
                setInput(input + value.toString())
            }
        }
    }

    return (
        <SideMenu>
            <Card>
                <Text>Total a facturar</Text>
                <Metric>$ { checkoutList.reduce((acc, product) => acc + (product.salePrice * product.quantity), 0) }</Metric>
                
                <Flex className="mb-2">
                    <TabGroup className="w-64">
                        <Subtitle className="mt-3">Metodo de pago</Subtitle>
                        <TabList variant="solid" value={mode} onVolumeChange={setMode}>
                            <Tab value='posCash'>Contado</Tab>
                            <Tab value='posCard'>Tarjeta</Tab>
                        </TabList>
                    </TabGroup>
                    <div className="w-full mt-4">
                        <Subtitle>Dinero recibido</Subtitle>
                        <NumberInput value={input} />
                    </div>
                </Flex>
                

                <Subtitle>Cambio</Subtitle>
                <Title>$ { Math.max(0 ,input - checkoutList.reduce((acc, product) => acc + (product.salePrice * product.quantity), 0)) }</Title>

                <Button color="green" className="w-full mt-4" onClick={ checkout }>Confirmar Pago</Button>
                <Grid numItems={2} className="gap-4">

                    <Button variant="secondary" color="blue" className="w-full mt-4">Editar Orden</Button>
                    <Button variant="secondary" color="rose" className="w-full mt-4">Cancelar Orden</Button>
                </Grid>
            </Card>
            <Grid numItems={1} numItemsSm={2} className="mt-4 gap-4">
                <Card>
                    <Grid numItems={3} className="gap-2">
                        <Button onClick={ () => onNumberPadClick(1) }>
                            1
                        </Button>
                        <Button onClick={ () => onNumberPadClick(2) }>
                            2
                        </Button>
                        <Button onClick={ () => onNumberPadClick(3) }>
                            3
                        </Button>
                        <Button onClick={ () => onNumberPadClick(4) }>
                            4
                        </Button>
                        <Button onClick={ () => onNumberPadClick(5) }>
                            5
                        </Button>
                        <Button onClick={ () => onNumberPadClick(6) }>
                            6
                        </Button>
                        <Button onClick={ () => onNumberPadClick(7) }>
                            7
                        </Button>
                        <Button onClick={ () => onNumberPadClick(8) }>
                            8
                        </Button>
                        <Button onClick={ () => onNumberPadClick(9) }>
                            9
                        </Button>
                        <Button onClick={ () => onNumberPadClick(0) }>
                            0
                        </Button>
                        <Button onClick={ () => onNumberPadClick('ENTER') }>
                            ENTER
                        </Button>
                        <Button onClick={ () => onNumberPadClick('DEL') }>
                            DEL
                        </Button>
                    </Grid>
                </Card>

                <Card>
                    <Title>Productos</Title>

                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableHeaderCell>Producto</TableHeaderCell>
                                <TableHeaderCell>Cantidad</TableHeaderCell>
                                <TableHeaderCell>Precio</TableHeaderCell>
                                <TableHeaderCell>Subtotal</TableHeaderCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {checkoutList.map((product) => (
                                <TableRow key={product.id}>
                                    <TableHeaderCell>{product.name}</TableHeaderCell>
                                    <TableHeaderCell>{product.quantity}</TableHeaderCell>
                                    <TableHeaderCell>{product.salePrice}</TableHeaderCell>
                                    <TableHeaderCell>{product.salePrice * product.quantity}</TableHeaderCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </Card>
            </Grid>
            
        </SideMenu>
    )
}

export default Checkout