import { useParams } from 'react-router-dom'
import { updateVariant } from '../../services/variants'
import { useVariant } from '../../hooks/variants'
import { useEffect, useState } from 'react'
import { Button, Callout } from '@tremor/react'
import { ExclamationCircleIcon, SaveAsIcon } from '@heroicons/react/solid'
import { readAsDataURL, toBase64 } from './CreateProductVariant'
import { removeImage, uploadMultipleImages } from '../../services/images'
import Loader from '../../components/Loader'
import ContainerCard from '../../components/ContainerCard'
import SideMenu from '../../components/SideMenu'
import ProductVariantForm from './_components/ProductVariantForm'

function UpdateProductVariant () {
  const { pid, id } = useParams()
  const variant = useVariant(pid, id)

  const [isLoading, setIsLoading] = useState(false)
  const [localVariant, setLocalVariant] = useState(variant)
  const [localResources, setLocalResources] = useState(null)
  const [errors, setErrors] = useState({})
  const [notifications, setNotifications] = useState({})

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
      setNotifications({ title: 'Variante actualizada correctamente' })
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
          setNotifications({ title: 'Imagen borrada correctamente' })
        } else {
          setErrors({ title: 'Error al borrar la imagen' })
        }
      }

      // Add images
      const response = await uploadMultipleImages(pid, id, toAdd.filter((i) => i.dat !== null))
      if (response.status !== 200) {
        setErrors({ title: 'Error al subir las imagenes' })
      } else if (toAdd.length > 0) {
        setNotifications({ title: 'Imagenes subidas correctamente' })
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

  if (variant === null || localResources === null) {
    return <Loader />
  }

  return (
    <SideMenu>
      <ContainerCard
        title='Update Product Variant' action={
          <div className=''>
            <Button icon={SaveAsIcon} onClick={(e) => { update(e) }} className='mx-1' loading={isLoading}>Guardar</Button>
          </div>
            }
      />

      {errors.title &&
        <Callout color='rose' className='mt-2' title='Error' icon={ExclamationCircleIcon}>
          {errors.title}
        </Callout>}

      {notifications.title &&
        <Callout color='green' className='mt-2' title='Exito' icon={ExclamationCircleIcon}>
          {notifications.title}
        </Callout>}

      <ProductVariantForm
        productVariant={{ ...localVariant, images: localResources }}
        setVariant={setLocalVariant}
        resources={localResources}
        setResources={setLocalResources}
        imageHandler={addImages}
      />
    </SideMenu>
  )
}

export default UpdateProductVariant
