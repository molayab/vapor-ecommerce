import { useParams } from 'react-router-dom'
import { fetchVariantSales, updateVariant } from '../../services/variants'
import { useVariant } from '../../hooks/variants'
import { useEffect, useState } from 'react'
import { Button, Card, Flex, List, ListItem, Metric, Subtitle, Title } from '@tremor/react'
import { SaveAsIcon } from '@heroicons/react/solid'
import { readAsDataURL, toBase64 } from './CreateProductVariant'
import { removeImage, uploadMultipleImages } from '../../services/images'
import Loader from '../../components/Loader'
import ContainerCard from '../../components/ContainerCard'
import SideMenu from '../../components/SideMenu'
import ProductVariantForm from './_components/ProductVariantForm'
import { useProduct } from '../../hooks/products'
import { toast } from 'react-toastify'
import { currencyFormatter, dateTimeFormatter } from '../../helpers/dateFormatter'

function UpdateProductVariant () {
  const { pid, id } = useParams()
  const variant = useVariant(pid, id)
  const product = useProduct(pid)

  const [isLoading, setIsLoading] = useState(false)
  const [localVariant, setLocalVariant] = useState(variant)
  const [localResources, setLocalResources] = useState(null)
  const [sales, setSales] = useState(null)

  let variantImages = []
  let resourcesImages = []

  const update = async (e) => {
    setIsLoading(true)
    const response = await updateVariant(pid, id, {
      ...localVariant,
      images: localResources.filter((i) => i.dat),
      availability: localVariant.availability || localVariant.isAvailable || false,
      isAvailable: localVariant.availability
    })

    const data = response.data
    if (data.id) {
      toast('Variante actualizada correctamente')
      let toRemove = []
      const toAdd = []

      toRemove = variant.images.map((i) => ({ url: i })).filter((i) => i.url.match(/t512_/)).filter((i) => {
        // filter the images in the variant that are not in the local resources
        return !localResources.map((i) => ({ url: i.url })).find((j) => j.url === i.url)
      })

      for (let i = 0; i < localResources.length; i++) {
        const resource = localResources[i]
        if (resource.dat) {
          toAdd.push(resource)
        }
      }

      // Remove images
      for (let i = 0; i < toRemove.length; i++) {
        const image = toRemove[i]
        const response = await removeImage(pid, id, image.url)

        if (response.status === 200) {
          toast('Imagen borrada correctamente')
        } else {
          toast('Error al borrar la imagen')
        }
      }

      // Add images
      const response = await uploadMultipleImages(pid, id, toAdd.filter((i) => i.dat !== null))
      if (response.status !== 200) {
        toast('Error al subir las imagenes')
      } else if (toAdd.length > 0) {
        toast('Imagenes subidas correctamente')
      }

      setIsLoading(false)
    } else {
      setIsLoading(false)
    }
  }

  const addImages = async (e) => {
    const images = e.target.files
    const r = []
    for (let i = 0; i < images.length; i++) {
      const file = await readAsDataURL(images[i])
      r.push({
        dat: await toBase64(images[i]),
        ext: file.ext,
        name: file.name,
        size: file.size
      })
    }
    setLocalResources((old) => [...old, ...r])
  }

  useEffect(() => {
    if (variant !== null && variantImages.length === 0) {
      variantImages = variant.images.map((i) => ({ url: i })).filter((i) => i.url.match(/t512_/))
      resourcesImages = [
        ...variantImages
      ]
    }

    setLocalResources(resourcesImages)
    setLocalVariant(variant)
  }, [variant])

  useEffect(() => {
    async function fetchVariantSalesX (id) {
      const response = await fetchVariantSales(id)
      if (response.status !== 200) {
        toast('Error al obtener las ventas')
        return
      }

      setSales(response.data)
    }

    if (variant !== null) {
      fetchVariantSalesX(variant.id)
    }
  }, [variant])

  if (variant === null || localResources === null || product === null) {
    return <Loader />
  }

  console.log(sales)
  return (
    <SideMenu>
      <ContainerCard
        isSticky
        subtitle='Editar la variante de'
        title={product.title} action={
          <div className=''>
            <Button icon={SaveAsIcon} onClick={(e) => { update(e) }} className='mx-1' loading={isLoading}>Guardar</Button>
          </div>
            }
      />

      <div className='py-4' />

      <ProductVariantForm
        productVariant={{ ...localVariant, images: localResources }}
        setVariant={setLocalVariant}
        resources={localResources}
        setResources={setLocalResources}
        imageHandler={addImages}
      />

      <Card className='mt-2' decoration='top' color='red'>
        <Flex className='gap-8'>
          <div className='flex-none'>
            <Metric>Ventas</Metric>
            <Subtitle>Estas son las ventas de la variante</Subtitle>

            <Title>Total dinero recaudado</Title>
            <Metric color='yellow'>
              {sales && currencyFormatter(sales.reduce((acc, sale) => {
                return acc + sale.total
              }, 0))}
            </Metric>

            <Title>Total unidades vendidas</Title>
            <Metric color='green'>
              {sales && sales.reduce((acc, sale) => {
                return acc + sale.quantity
              }, 0)}
            </Metric>

            <Title>Total dinero de ganancias</Title>
            <Metric color='green'>
              {sales && currencyFormatter(sales.reduce((acc, sale) => {
                return acc + sale.total - variant.price
              }, 0))}
            </Metric>
          </div>
          <div className='flex-1'>
            <List>
              <ListItem>
                <span><strong>Fecha</strong></span>
                <span><strong>Total</strong></span>
              </ListItem>
              {sales && sales.map((sale) => (
                <ListItem key={sale.id}>
                  <span>{dateTimeFormatter(sale.createdAt)} ({sale.quantity})</span>
                  <span>{currencyFormatter(sale.total)}</span>
                </ListItem>
              ))}
            </List>
          </div>
        </Flex>
      </Card>
    </SideMenu>
  )
}

export default UpdateProductVariant
