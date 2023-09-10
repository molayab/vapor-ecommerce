import {
  Card,
  Flex,
  Grid,
  NumberInput,
  Select,
  SelectItem,
  Subtitle,
  Title
} from '@tremor/react'

import { PencilIcon, SearchCircleIcon, TrashIcon } from '@heroicons/react/outline'
import { useNavigate } from 'react-router-dom'
import { RES_URL } from '../../../App'
import { deleteProduct } from '../../../services/products'
import RateStarList from '../../../components/RateStarList'

function ProductGridCard ({ products, setProducts }) {
  const navigate = useNavigate()
  const deleteProductAction = async (id) => {
    if (window.confirm('¿Estas seguro de eliminar este producto?')) {
      console.log('Deleting product with id: ' + id)
      if ((await deleteProduct(id)).status === 200) {
        setProducts(products.filter((p) => p.id !== id))
      }
    }
  }

  return (
    <>
      {products.length === 0 && (
        <Card className='mt-4'>
          <SearchCircleIcon className='w-12 h-12 text-gray-400' />
          <Subtitle className='mt-4'>No se encontraron productos</Subtitle>
        </Card>
      )}
      <Grid numItems={1} numItemsSm={1} numItemsMd={1} numItemsLg={3} className='gap-4 mt-4'>

        {products.map((product, index) => (
          <Card
            key={index}
            decorationColor={product.isAvailable ? 'green' : 'rose'}
            decoration='bottom'
            className='hover:cursor-pointer hover:border-lime-100'
          >
            <div className='flex items-start gap-4' onClick={() => navigate(`/products/${product.id}`)}>
              <figure className='max-w-lg flex-none w-[100px] h-[100px]'>
                {
                  product.variants && product.variants.length > 0
                    ? (
                      <img
                        className='h-full w-full rounded-lg' src={
                          product.variants.reduce((acc, v) => {
                            const image = v.images.reduce((acc, i) => {
                              if (i) return i
                              return acc
                            }, null)
                            if (image) return RES_URL + '/' + image
                            return acc
                          }, '')
                      } alt='Image description'
                      />
                      )
                    : (
                      <img className='h-auto max-w-full rounded-lg' src='https://placehold.co/512' alt='Image description' />
                      )
                }

                <figcaption className='mt-2 text-sm text-center text-gray-500 dark:text-gray-400'>Image caption</figcaption>
              </figure>
              <div className='flex-1'>
                <Title>{product.title}</Title>
                <Subtitle>{product.minimumSalePrice}</Subtitle>
                <Subtitle>{product.subtitle}</Subtitle>
                <RateStarList rate={product.stars} />
              </div>
              <div>
                <Title className='text-right'>
                  {product.averageSalePrice}
                </Title>
                <Subtitle>
                  precio promedio
                </Subtitle>
              </div>
            </div>

            <Flex className='mt-4'>
              <div className=''>
                <Subtitle>Disponibles</Subtitle>
                <NumberInput placeholder='Inventario' value={product.stock} aria-label='Inventario' readOnly disabled />
              </div>
              <div className=''>
                <Subtitle>Acciones</Subtitle>
                <Select onValueChange={(e) => {
                  switch (e) {
                    case '1':
                      deleteProductAction(product.id)
                      break
                    case '2':
                      navigate(`/products/${product.id}`)
                      break
                  }
                }}
                >
                  <SelectItem value='1' icon={TrashIcon}>Eliminar</SelectItem>
                  <SelectItem value='2' icon={PencilIcon}>Editar</SelectItem>
                </Select>
              </div>
            </Flex>
          </Card>
        )
        )}
      </Grid>
    </>
  )
}

export default ProductGridCard
