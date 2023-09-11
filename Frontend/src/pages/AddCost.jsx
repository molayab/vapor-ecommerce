import { Button, DatePicker, Flex, Grid, Select, SelectItem, Text, TextInput, Title } from '@tremor/react'
import ContainerCard from '../components/ContainerCard'
import SideMenu from '../components/SideMenu'
import { CodeIcon } from '@heroicons/react/solid'
import { CurrencyDollarIcon, ExclamationIcon } from '@heroicons/react/outline'
import { useState } from 'react'
import Loader from '../components/Loader'
import { request } from '../services/request'
import { toast } from 'react-toastify'

function AddCost () {
  const [isLoading, setIsLoading] = useState(false)
  const [cost, setCost] = useState({
    currency: 'COP',
    startDate: new Date()
  })

  const addCost = async () => {
    setIsLoading(true)
    try {
      console.log({
        ...cost,
        amount: parseFloat(cost.amount),
        startDate: cost.startDate.toISOString().split('.')[0] + 'Z'
      })
      const response = await request.post('/finance/costs', {
        ...cost,
        amount: parseFloat(cost.amount),
        startDate: cost.startDate.toISOString().split('.')[0] + 'Z'
      })
      if (response.status === 201 || response.status === 200) {
        toast('Costo agregado correctamente')
        setCost({
          currency: 'COP'
        })
      }
    } catch (e) {
      if (e.response.data.reason) {
        toast(e.response.data.reason)
      } else {
        toast('Error al agregar el costo')
      }
    }
    setIsLoading(false)
  }

  if (isLoading) {
    return (<Loader />)
  }

  return (
    <SideMenu>
      <ContainerCard title='Agregar Costo' subtitle='Egresos de la tienda'>
        <Text className='mt-2'>Los costos son egresos de la tienda, como por ejemplo el pago de la renta, el pago de servicios, etc.</Text>

        <Grid numItems={1} numItemsSm={2} className='gap-1 mt-4'>
          <div>
            <Select icon={CodeIcon} value={cost.type} onChange={(e) => setCost((old) => ({ ...old, type: e }))} placeholder='Seleccionar tipo de costo'>
              <SelectItem value='fixed'>Fijo</SelectItem>
              <SelectItem value='variable'>Variable</SelectItem>
            </Select>
            <Text className='mt-2'>
              <b>Tipo de costo:</b> fijo o variable, los costos fijos son aquellos que no cambian con el tiempo, como por ejemplo el pago de la renta, el pago de servicios, etc.
            </Text>
          </div>
          <div>
            <Select value={cost.periodicity} onChange={(e) => setCost((old) => ({ ...old, periodicity: e }))} placeholder='Seleccionar periodicidad'>
              <SelectItem value='oneTime'>Pago unico</SelectItem>
              <SelectItem value='daily'>Diario</SelectItem>
              <SelectItem value='weekly'>Semanal</SelectItem>
              <SelectItem value='biweekly'>Quincenal</SelectItem>
              <SelectItem value='monthly'>Mensual</SelectItem>
              <SelectItem value='bimonthly'>Bimestral</SelectItem>
              <SelectItem value='quarterly'>Trimestral</SelectItem>
              <SelectItem value='semiannually'>Semestral</SelectItem>
              <SelectItem value='yearly'>Anual</SelectItem>
            </Select>
            <Text className='mt-2'>
              <b>Periodicidad:</b> es la frecuencia con la que se paga el costo, por ejemplo, si el costo es mensual, se paga cada mes. Todos los costos son aplicados al momento de creados, a partir de ese momento comienzan a ser aplicados los cobros periodicos.
            </Text>
          </div>
        </Grid>

        <Title className='mt-4'>Informacion basica del costo</Title>
        <TextInput value={cost.name} onChange={(e) => setCost((old) => ({ ...old, name: e.target.value }))} icon={ExclamationIcon} placeholder='Titulo del costo' />

        <Title className='mt-4'>Informacion financiera del costo</Title>
        <Flex className='mt-4'>
          <TextInput value={cost.amount} type='number' icon={CurrencyDollarIcon} onChange={(e) => setCost((old) => ({ ...old, amount: e.target.value }))} placeholder='Monto del costo' />
          <Select icon={CurrencyDollarIcon} value={cost.currency} placeholder='Seleccionar moneda'>
            <SelectItem value='COP'>COP</SelectItem>
          </Select>
        </Flex>
        <Title className='my-4'>¿Cuando se efectuo el gasto?</Title>
        <DatePicker value={cost.startDate} onValueChange={(e) => setCost((old) => ({ ...old, startDate: e }))} placeholder='Seleccionar fecha de inicio' />

        <Button onClick={(e) => addCost()} className='my-4 w-full'>Agregar Costo</Button>
      </ContainerCard>
    </SideMenu>
  )
}

export default AddCost
