import { Button, Card, Icon, List, ListItem, Text, TextInput, Title } from '@tremor/react'
import ContainerCard from '../components/ContainerCard'
import SideMenu from '../components/SideMenu'
import { CheckCircleIcon } from '@heroicons/react/solid'
import { fetchOrderItems, returnProductVariants } from '../services/orders'
import { useState } from 'react'
import { toast } from 'react-toastify'
import { currencyFormatter } from '../helpers/dateFormatter'
import { PlusCircleIcon } from '@heroicons/react/outline'
import { useNavigate } from 'react-router-dom'

function ReturnProductVariants () {
  const navigate = useNavigate()
  const [id, setId] = useState(null)
  const [items, setItems] = useState([{}])
  const [skus, setSkus] = useState([{}])
  const search = async (id) => {
    const response = await fetchOrderItems(id)
    if (response.status !== 200) {
      toast('Error al obtener los items de la orden')
      return
    }

    setItems(response.data)
  }

  const confirm = async () => {
    if (skus.length === 0) {
      toast('No se ha seleccionado ningun item')
      return
    }

    const _skus = skus.map((e) => e.sku).filter((e) => e !== undefined)
    const response = await returnProductVariants(id, _skus)
    if (response.status !== 200) {
      toast('Error al realizar la devolución')
      return
    }

    toast('Devolución realizada correctamente')
    navigate('/pos/promo/' + response.data.promoCode)
  }

  return (
    <SideMenu>
      <ContainerCard
        title='Realizar una devolución'
        subtitle='Ingresa el codigo o guia de la devolución'
      >
        <TextInput value={id} onChange={(e) => setId(e.target.value)} placeholder='Codigo o guia de la devolución' />
        <Button onClick={(e) => {
          search(id)
        }}
        >Buscar
        </Button>

      </ContainerCard>

      <Card>
        <Title>Detalles de la devolución</Title>
        <List className='py-2'>
          {items.map((item) => (
            <ListItem
              key={item.id} className='hover:bg-slate-800' onClick={() => {
                if (skus.map((e) => e.id).includes(item.id)) {
                  setSkus((o) => o.filter((i) => i.id !== item.id))
                } else {
                  setSkus([...skus, item])
                }
              }}
            >
              <div className='flex justify-center items-center py-4'>
                {skus.map((e) => e.id).includes(item.id) ? <Icon icon={CheckCircleIcon} /> : <Icon icon={PlusCircleIcon} />}
                <div>
                  <span className='ml-2'>{item.name}</span>
                  <span className='ml-2'>{item.sku}</span>
                  <br />
                  <span className='ml-2'>Impuesto: {item.tax * 100}%</span>
                  <span className='ml-2'>- {currencyFormatter(item.salePrice * item.tax)}</span>

                </div>
              </div>
              <span><Text color='red'>- {currencyFormatter((item.salePrice * item.tax) + item.salePrice)}</Text></span>
            </ListItem>
          ))}
        </List>
        <Button
          onClick={(e) => { confirm() }}
        >
          Confirmar la selección
        </Button>
      </Card>
    </SideMenu>
  )
}

export default ReturnProductVariants
