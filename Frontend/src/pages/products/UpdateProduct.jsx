import {
  ExclamationCircleIcon,
  EyeIcon,
  EyeOffIcon,
  SaveIcon,
  TrashIcon
} from '@heroicons/react/solid'

import { useEffect, useState } from 'react'
import { Button, Callout } from '@tremor/react'
import { useParams, useNavigate } from 'react-router-dom'
import { useProduct } from '../../hooks/products'
import { deleteProduct, updateProduct } from '../../services/products'
import Loader from '../../components/Loader'
import ProductForm from './_components/ProductForm'
import ContainerCard from '../../components/ContainerCard'
import SideMenu from '../../components/SideMenu'
import { toast } from 'react-toastify'

function UpdateProduct () {
  const navigate = useNavigate()
  const { id } = useParams()

  const product = useProduct(id)
  const [isLoading, setIsLoading] = useState(false)
  const [localProduct, setLocalProduct] = useState(null)
  const [errors, setErrors] = useState({})
  const [isPublished, setIsPublished] = useState(false)

  useEffect(() => {
    if (product) {
      setLocalProduct(product)
      setIsPublished(product.isPublished)
    }
  }, [product])

  const deleteAction = async (e) => {
    e.preventDefault()

    if (!window.confirm('¿Estas seguro de borrar este producto?, esta acción no se puede deshacer!.\n\nAl borrar el producto, se borraran todas las variantes y recursos asociados.')) { return }
    if (await deleteProduct(id)) navigate('/products')
  }

  const updateAction = async () => {
    if (localProduct) {
      setErrors({})
      setIsLoading(true)
      const response = await updateProduct(id, {
        title: localProduct.title,
        description: localProduct.description,
        isPublished,
        category: localProduct.category.id || localProduct.category || product.category.id
      })
      if (response.status !== 200) {
        toast('Error al actualizar el producto')
        setIsLoading(false)
        return
      }

      const data = response.data
      if (data.id) {
        toast('Producto actualizado correctamente')
      }
      setIsLoading(false)
    } else setErrors({ title: 'La información del producto es requerida' })
  }

  const updateVariant = async (variant) => {
    if (localProduct) {
      setErrors({})
      setIsLoading(true)
      const response = await updateProduct(id, { ...localProduct, isPublished, category: localProduct.category.id })
      const data = response.data
      if (data.id) {
        setIsLoading(false)
        navigate('/products/' + id + '/variant')
      }
    } else setErrors({ title: 'La información del producto es requerida' })
  }

  if (product === null) {
    return <Loader />
  }

  return (
    <SideMenu>
      <ContainerCard
        isSticky
        title={product.title} subtitle='Editar el producto' action={
          <div className=''>
            <Button
              type='button'
              isLoading={isLoading}
              onClick={(e) => deleteAction(e)}
              className='mx-1'
              color='rose'
              variant='secondary'
              icon={TrashIcon}
            >Borrar Producto
            </Button>
            <Button
              type='button'
              isLoading={isLoading}
              variant='secondary'
              color={isPublished ? 'rose' : 'green'}
              onClick={(e) => setIsPublished(!isPublished)}
              icon={!isPublished ? EyeIcon : EyeOffIcon}
              className='mx-1'
            >{isPublished ? 'Despublicar' : 'Publicar'}
            </Button>
            <Button
              type='button'
              isLoading={isLoading}
              onClick={(e) => { updateAction() }}
              icon={SaveIcon}
              variant='secondary'
            >Guardar
            </Button>
          </div>
}
      />

      {errors.title &&
        <Callout color='rose' className='mt-2' title='Error' icon={ExclamationCircleIcon}>
          {errors.title}
        </Callout>}

      <ProductForm product={localProduct} setProduct={setLocalProduct} onSave={updateVariant} />
    </SideMenu>
  )
}

export default UpdateProduct
