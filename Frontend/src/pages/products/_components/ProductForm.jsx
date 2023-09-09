import {
  Button,
  Card,
  Divider,
  Flex,
  Grid,
  Metric,
  Select,
  SelectItem,
  Subtitle,
  TextInput,
  Title
} from '@tremor/react'

import Loader from '../../../components/Loader'
import { useCategories } from '../../../hooks/categories'
import { CurrencyDollarIcon, SearchIcon } from '@heroicons/react/solid'
import { createCategory } from '../../../services/categories'
import { useNavigate, useParams } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { deleteVariant } from '../../../services/variants'
import VariantList from '../../variants/_components/VariantList'

const { alert, confirm, prompt } = window

function ProductForm ({ product, setProduct, onSave }) {
  const { id } = useParams()
  const navigate = useNavigate()
  const categories = useCategories()
  const [localCategories, setLocalCategories] = useState(null)
  const [errors, setErrors] = useState({})
  const [isLoading, setIsLoading] = useState(false)
  const [productCopy, setProductCopy] = useState(null)

  useEffect(() => {
    setLocalCategories(categories)
  }, [categories])

  useEffect(() => {
    setProductCopy(product)
  }, [product])

  product = { ...product }
  if (product.variants === undefined) {
    product.variants = []
  }

  if (isLoading) {
    return <Loader />
  }

  // Show loader if categories are not loaded
  if (categories === null || localCategories === null || productCopy === null) {
    return <Loader />
  }

  const deleteProductVariant = async (variant, index) => {
    if (confirm('¿Estas seguro de borrar esta variante?, esta acción no se puede deshacer!')) {
      // product.variants.splice(index, 1)
      // setProduct(product)

      setIsLoading(true)
      const response = await deleteVariant(id, variant.id)
      if (response.status === 200) {
        setProduct({ ...product, variants: product.variants.filter((v) => v.id !== variant.id) })
      }
      setIsLoading(false)
    }
  }

  const addCategory = async (e) => {
    const name = prompt('Nombre de la categoria:')
    if (name === null || name === '') {
      return alert('Category name is required')
    }

    const id = await createCategory(name)
    if (id === null) {
      return alert('Error al crear la categoria')
    }

    setLocalCategories([...localCategories, { id, name }])
    console.log({ id, name })
  }

  const validateProduct = () => {
    setErrors({})

    if (product.title === undefined || product.title === '') {
      setErrors({ title: 'Product title is required' })
    }

    if (product.description === undefined || product.description === '') {
      setErrors({ description: 'Product description is required' })
    }

    if (product.category === undefined || product.category === '') {
      setErrors({ category: 'Product category is required' })
    }
  }

  const filterVariantsBySku = (sku) => {
    if (sku === '') {
      return setProductCopy({ ...product })
    }
    setProductCopy((old) => {
      return {
        ...old,
        variants: old.variants.filter((v) => v.sku.includes(sku))
      }
    }
    )
  }

  const addVariant = () => {
    validateProduct()
    onSave()
  }

  return (
    <>
      <Title className='mt-4'>Informacion basica del producto</Title>
      <Card className='mt-4'>
        <Subtitle className='mb-4'>Titulo del producto</Subtitle>
        <TextInput
          error={errors.title}
          errorMessage={errors.title}
          name='productName'
          value={product.title}
          aria-required='true'
          onChange={(e) => setProduct({ ...product, title: e.target.value })}
          className='my-2'
          placeholder='Vestido de baño completo'
        />
        <Subtitle className='mt-4'>Descripcion del producto</Subtitle>
        <TextInput
          name='productDescription'
          error={errors.description}
          errorMessage={errors.description}
          value={product.description}
          aria-required='true'
          onChange={(e) => setProduct({ ...product, description: e.target.value })}
          className='my-2'
          placeholder='Hermoso vestido de baño completo para dama'
        />

        <Grid direction='row' numItems={1} numItemsSm={2} numItemsMd={2} numItemsLg={2} className='gap-4 my-4'>
          <div>
            <Subtitle>Costo promedio</Subtitle>
            <TextInput icon={CurrencyDollarIcon} value={product.variants.reduce((a, b) => a + b.price, 0) / product.variants.length} placeholder='$ 0.00' readOnly disabled />
          </div>

          <div>
            <Subtitle>Venta promedio</Subtitle>
            <TextInput icon={CurrencyDollarIcon} value={product.variants.reduce((a, b) => a + b.salePrice, 0) / product.variants.length} placeholder='$ 0.00' readOnly disabled />
          </div>
        </Grid>

        <Subtitle className='mt-4 mb-2'>Categoria</Subtitle>
        <Flex className='gap-2' error={errors.category} errorMessage={errors.category}>
          <Select onChange={(e) => setProduct({ ...product, category: e })} value={product.category.id} className='w-full'>
            {localCategories.map((category) => {
              console.log(category)
              return (
                <SelectItem key={category.id} value={category.id}>{category.title || category.name || category.id}</SelectItem>
              )
            })}
          </Select>
          <Button onClick={(e) => { addCategory(e) }}>Agregar Categoria</Button>
        </Flex>

        <Divider className='my-8' />
        <Metric className='my-2'>Variantes</Metric>

        <Flex className='gap-4 my-4'>
          <TextInput
            icon={SearchIcon}
            onChange={(e) => { filterVariantsBySku(e.target.value) }}
            className='w-full' placeholder='Buscar'
          />
          <Button onClick={(e) => addVariant(e)}>Agregar Variante</Button>
        </Flex>

        <VariantList productCopy={productCopy} navigate={navigate} id={id} deleteProductVariant={deleteProductVariant} />
      </Card>
    </>
  )
}

export default ProductForm
