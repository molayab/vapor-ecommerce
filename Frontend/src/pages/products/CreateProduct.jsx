import SideMenu from '../../components/SideMenu'
import ContainerCard from '../../components/ContainerCard'
import Loader from '../../components/Loader'
import ProductForm from './_components/ProductForm'
import { useNavigate } from 'react-router-dom'
import { useState } from 'react'
import { Button, Callout } from '@tremor/react'
import { ExclamationCircleIcon, EyeIcon, EyeOffIcon, SaveIcon } from '@heroicons/react/solid'
import { createProduct } from '../../services/products'
import { toast } from 'react-toastify'

function CreateProduct () {
  const navigate = useNavigate()
  const product = {
    title: '',
    description: '',
    category: ''
  }

  const [isLoading, setIsLoading] = useState(false)
  const [localProduct, setLocalProduct] = useState(product)
  const [errors, setErrors] = useState({})
  const [isPublished, setIsPublished] = useState(true)

  if (product === null) {
    return <Loader />
  }

  const createProductX = async () => {
    if (localProduct) {
      setIsLoading(true)
      const response = await createProduct({ ...localProduct, isPublished })
      const data = response.data
      if (data.id) {
        setIsLoading(false)
        toast('Producto creado correctamente')
        navigate('/products/' + data.id)
      }
    } else {
      toast('Error al crear el producto')
    }
  }

  const createVariant = async () => {
    if (localProduct) {
      setErrors({})
      setIsLoading(true)

      const response = await createProduct({ ...localProduct, isPublished })
      const data = response.data
      if (data.id) {
        setIsLoading(false)
        navigate('/products/' + data.id + '/variant')
      }
    } else {
      setErrors({ title: 'Product information is required' })
    }
  }

  return (
    <SideMenu>
      <ContainerCard
        isSticky
        title='Producto' subtitle='Agregar un nuevo' action={
          <div className=''>
            <Button
              isLoading={isLoading}
              variant='secondary'
              color={isPublished ? 'rose' : 'green'}
              onClick={(e) => setIsPublished(!isPublished)}
              icon={!isPublished ? EyeIcon : EyeOffIcon}
              className='mx-1'
            >{isPublished ? 'Despublicar' : 'Publicar'}
            </Button>
            <Button
              isLoading={isLoading}
              onClick={(e) => { createProductX() }}
              icon={SaveIcon}
              variant='secondary'
            >Crear
            </Button>
          </div>
}
      />

      {errors.title &&
        <Callout color='rose' className='mt-2' title='Error' icon={ExclamationCircleIcon}>
          {errors.title}
        </Callout>}

      <ProductForm product={localProduct} setProduct={setLocalProduct} onSave={createVariant} />
    </SideMenu>
  )
}

export default CreateProduct
