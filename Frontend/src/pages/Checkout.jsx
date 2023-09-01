import { 
    Button, 
    Card, 
    Divider, 
    Flex, 
    Grid,
    Metric, 
    NumberInput, 
    Subtitle, 
    Tab, 
    TabGroup, 
    TabList, 
    Table, 
    TableBody, 
    TableHead, 
    TableHeaderCell, 
    TableRow, 
    Text, 
    TextInput, 
    Title 
} from "@tremor/react"

import { useState } from "react"
import { API_URL } from "../App"
import SideMenu from "../components/SideMenu"
import Keypad from "../components/Keypad"
import { toast } from "react-toastify"
import { useNavigate } from "react-router-dom"

export function Checkout({ checkoutList, setPay, setCheckoutList }) {
    const [input, setInput] = useState('0')
    const [mode, setMode] = useState('posCash')
    const navigate = useNavigate()
    const [isLoading, setIsLoading] = useState(false)
    const [shouldBill, setShouldBill] = useState(true)

    const [clientName, setClientName] = useState('')
    const [clientEmail, setClientEmail] = useState('')

    const dataFormatter = (number) => {
        return "$ " + Intl.NumberFormat("us").format(number).toString();
    }

    const checkout = async () => {
        if (clientEmail === '' && shouldBill) {
            alert('Debe ingresar un email')
            return
        }

        setIsLoading(true)
        console.log(mode)
        let response = await fetch(API_URL + '/orders/checkout/' + mode, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                shippingAddressId: null,
                billingAddressId: null,
                billTo: shouldBill ? {
                    name: clientName,
                    email: clientEmail
                } : null,
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
            toast('Orden creada con exito')

            setCheckoutList([])
            setPay(false)
        } else {
            toast('Error al crear la orden')
        }

        setIsLoading(false)
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
                <Metric>{ dataFormatter(checkoutList.reduce((acc, product) => acc + (product.salePrice * product.quantity), 0)) }</Metric>
                
                <Flex className="mb-2">
                    <TabGroup className="w-64">
                        <Subtitle className="mt-3">Metodo de pago</Subtitle>
                        <TabList variant="solid">
                            <Tab onClick={(e) => setMode("posCash")}>Contado</Tab>
                            <Tab onClick={(e) => setMode("posCard")}>Tarjeta</Tab>
                        </TabList>
                    </TabGroup>
                    <div className="w-full mt-4">
                        <Subtitle>Dinero recibido</Subtitle>
                        <NumberInput value={input} />
                    </div>
                </Flex>

                <TabGroup className="w-64 mt-4 mb-4">
                    <TabList variant="solid">
                        <Tab onClick={(e) => setShouldBill(true)}>Factura por correo</Tab>
                        <Tab onClick={(e) => setShouldBill(false)}>No enviar factura</Tab>
                    </TabList>
                </TabGroup>
                
                { shouldBill && (
                    <>
                    <Title>Datos de facturacion</Title>                   

                    <TextInput 
                        value={clientEmail} 
                        onChange={ (e) => setClientEmail(e.target.value) }
                        className="w-full mt-4" placeholder="Email del cliente" required />
                    <TextInput 
                        value={clientName}
                        onChange={ (e) => setClientName(e.target.value) }
                        className="w-full mt-4" 
                        placeholder="Nombre del cliente" />
                    </>
                )}

                <Divider />
                <Subtitle>Cambio</Subtitle>
                <Title>{ dataFormatter(Math.max(0 ,input - checkoutList.reduce((acc, product) => acc + (product.salePrice * product.quantity), 0))) }</Title>

                <Button 
                    loading={isLoading}
                    color="green" size="xl" className="w-full mt-4" onClick={ checkout }>Confirmar Pago</Button>
                <Grid numItems={1} className="gap-4">
                    <Button 
                        onClick={(e) => { setPay(false) }}
                        size="sm" variant="secondary" color="rose" className="w-full mt-4">Cancelar Orden</Button>
                </Grid>
            </Card>
            <Grid numItems={1} numItemsSm={2} className="mt-4 gap-4">
                <Keypad onNumberPadClick={ onNumberPadClick } />

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
                                    <TableHeaderCell>{dataFormatter(product.salePrice)}</TableHeaderCell>
                                    <TableHeaderCell>{dataFormatter(product.salePrice * product.quantity)}</TableHeaderCell>
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