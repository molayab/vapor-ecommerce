import {
  Button,
  Card,
  Divider,
  Grid,
  Metric,
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
} from '@tremor/react'

import { useEffect, useState } from 'react'
import SideMenu from '../components/SideMenu'
import Keypad from '../components/Keypad'
import { toast } from 'react-toastify'
import { request } from '../services/request'
import { currencyFormatter } from '../helpers/dateFormatter'

const { alert } = window

export function Checkout ({ checkoutList, setPay, setCheckoutList, promoCode }) {
  const [input, setInput] = useState('0')
  const [mode, setMode] = useState('posCash')
  const [isLoading, setIsLoading] = useState(false)
  const [shouldBill, setShouldBill] = useState(true)

  const [clientName, setClientName] = useState('')
  const [clientEmail, setClientEmail] = useState('')
  const [discount, setDiscount] = useState(null)

  const dataFormatter = (number) => {
    return '$ ' + Intl.NumberFormat('us').format(number).toString()
  }

  const fetchDiscount = async () => {
    try {
      const response = await request.get('/discounts/' + promoCode)
      const data = response.data
      if (data.discount) {
        setDiscount(data)
      }
    } catch (error) {
      console.log(error)
    }
  }

  useEffect(() => {
    if (promoCode) {
      fetchDiscount()
    }
  }, [])

  const checkout = async () => {
    if (clientEmail === '' && shouldBill) {
      alert('Debe ingresar un email')
      return
    }

    setIsLoading(true)

    try {
      const response = await request.post('/orders/checkout/' + mode, {
        shippingAddressId: null,
        billingAddressId: null,
        billTo: shouldBill
          ? {
              name: clientName,
              email: clientEmail
            }
          : null,
        promoCode,
        items: checkoutList.map((product) => ({
          productVariantId: product.id,
          quantity: product.quantity,
          price: product.salePrice,
          tax: product.tax
        }))
      })

      const data = response.data
      if (data.id) {
        toast('Orden creada con exito')

        setCheckoutList([])
        setPay(false)
      } else {
        toast('Error al crear la orden')
      }

      setIsLoading(false)
    } catch (error) {
      console.log(error)

      if (error.response.data.reason) {
        toast(error.response.data.reason)
      } else {
        toast('Error al crear la orden')
      }
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
        <Metric>{dataFormatter(checkoutList.reduce((acc, product) => acc + ((product.salePrice * product.quantity) + (product.salePrice * product.quantity * product.tax) - (discount ? Math.abs(discount.discount) : 0)), 0))}</Metric>
        {discount && (
          <Text color='rose'>{discount.code}: descuento por <strong>{discount.type === 'percentage' ? discount.discount + '%' : currencyFormatter(discount.discount)}</strong></Text>
        )}
        <Subtitle>Cambio</Subtitle>
        <Title color='gray'>{dataFormatter(input - checkoutList.reduce((acc, product) => acc + (product.salePrice * product.quantity), 0))}</Title>

        <Divider />
        <Grid numItems={1} numItemsSm={2} className='gap-4'>
          <Keypad onNumberPadClick={onNumberPadClick} placeholder='Dinero recibido' />
          <div>
            <TabGroup className='w-64 flex-none'>
              <Subtitle className='mt-3'>Metodo de pago</Subtitle>
              <TabList variant='solid'>
                <Tab onClick={(e) => setMode('posCash')}>Contado</Tab>
                <Tab onClick={(e) => setMode('posCard')}>Tarjeta</Tab>
              </TabList>
            </TabGroup>
            <TabGroup className='w-64 mt-4 mb-4 flex-1'>
              <Subtitle className='mt-3'>Facturacion</Subtitle>
              <TabList variant='solid'>
                <Tab onClick={(e) => setShouldBill(true)}>Factura por correo</Tab>
                <Tab onClick={(e) => setShouldBill(false)}>No enviar factura</Tab>
              </TabList>
            </TabGroup>

            {shouldBill && (
              <>
                <Title>Datos de facturacion</Title>

                <TextInput
                  value={clientEmail}
                  onChange={(e) => setClientEmail(e.target.value)}
                  className='w-full mt-4' placeholder='Email del cliente' required
                />
                <TextInput
                  value={clientName}
                  onChange={(e) => setClientName(e.target.value)}
                  className='w-full mt-4'
                  placeholder='Nombre del cliente'
                />
              </>
            )}
          </div>

        </Grid>
        <Button
          loading={isLoading}
          color='green' size='xl' className='w-full mt-4' onClick={checkout}
        >Confirmar Pago
        </Button>
        <Grid numItems={1} className='gap-4'>
          <Button
            onClick={(e) => { setPay(false) }}
            size='sm' variant='secondary' color='rose' className='w-full mt-4'
          >Cancelar Orden
          </Button>
        </Grid>
      </Card>
      <Grid numItems={1} className='mt-4 gap-4'>

        <Card>
          <Title>Productos</Title>

          <Table>
            <TableHead>
              <TableRow>
                <TableHeaderCell>Producto</TableHeaderCell>
                <TableHeaderCell>Cantidad</TableHeaderCell>
                <TableHeaderCell>Precio</TableHeaderCell>
                <TableHeaderCell>Impuesto</TableHeaderCell>
                <TableHeaderCell>Subtotal</TableHeaderCell>
                <TableHeaderCell>Total</TableHeaderCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {checkoutList.map((product) => (
                <TableRow key={product.id}>
                  <TableHeaderCell>{product.name}</TableHeaderCell>
                  <TableHeaderCell>{product.quantity}</TableHeaderCell>
                  <TableHeaderCell>{dataFormatter(product.salePrice)}</TableHeaderCell>
                  <TableHeaderCell>{dataFormatter(product.salePrice * product.quantity * product.tax)}</TableHeaderCell>
                  <TableHeaderCell>{dataFormatter(product.salePrice * product.quantity)}</TableHeaderCell>
                  <TableHeaderCell>{dataFormatter((product.salePrice * product.quantity) + (product.salePrice * product.quantity * product.tax))}</TableHeaderCell>
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
