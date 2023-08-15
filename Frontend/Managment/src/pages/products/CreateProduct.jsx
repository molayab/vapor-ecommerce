import SideMenu from "../../components/SideMenu";
import CategorySelector from "../../components/CategorySelector";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { API_URL } from "../../App";
import ContainerCard from "../../components/ContainerCard";
import { BarChart, Button, Card, Flex, Grid, Icon, Subtitle, Table, TableBody, TableCell, TableHead, TableHeaderCell, TableRow, TextInput, Title } from "@tremor/react"
import { TrashIcon } from "@heroicons/react/solid";
import { ArrowSmUpIcon, CurrencyDollarIcon } from "@heroicons/react/outline";


function CreateProduct() {
  const navigate = useNavigate()
  let refreshCategories = null
  
  const [product, _setProduct] = useState(JSON.parse(localStorage.getItem('product')) || { variants: [] })
  const [category, setCategory] = useState(null)
  const setProduct = (product) => {
    _setProduct(product)
    localStorage.setItem('product', JSON.stringify(product))
  }
  
  useEffect(() => {
    if (product.category) {
      setCategory(product.category)
    }
  }, [])
  
  const saveProduct = (e) => {
    e.preventDefault()
    console.log(document.querySelector('input[name="productName"]').value)
    const name = document.querySelector('input[name="productName"]').value;
    const description = document.querySelector('input[name="productDescription"]').value;
    
    const p = {
      title: name,
      description: description,
      category: category,
      variants: product.variants
    }
    
    setProduct(p)
  }
  
  const resetProduct = (e) => {
    e.preventDefault()
    localStorage.removeItem('product')
    setProduct({ variants: [] })
  }
  
  const deleteProductVariant = (e, index) => {
    e.preventDefault()
    const variants = product.variants
    variants.splice(index, 1)
    setProduct({ ...product, variants: variants })
  }
  
  const dataFormatter = (number) => {
    return "$ " + Intl.NumberFormat("us").format(number).toString();
  }

  const createVariant = (e) => {
    saveProduct(e)
    navigate("/products/new/variant")
  }
  
  const createCategory = async (e) => {
    e.preventDefault();
    
    let name = prompt("Category name");
    if (name === null || name === "") {
      alert("Category name is required");
      return;
    }
    
    const response = await fetch(API_URL + '/categories', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ title: name })
    });
    
    const data = await response.json();
    if (data.id) {
      if (refreshCategories) {
        refreshCategories();
        alert("Category created");
      }
    } else if (data.error) {
      alert(data.reason);
    }
  }
  
  const categoryBuilder = (isFetched, e) => {
    if (isFetched === false && e !== undefined) {
      refreshCategories = e;
    }
  }
  
  const publishProduct = async (e) => {
    e.preventDefault();
    
    if (product === null) {
      alert("No hay un producto para publicar")
      return
    }
    if (product.variants.length === 0) {
      alert("Agrega por lo menos una variante")
      return
    }
    
    console.log(product);
    
    const response = await fetch(API_URL + '/products', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(product)
    });
    
    const data = await response.json();
    if (data.id) {
      resetProduct(e)
      navigate("/products")
    } else if (data.error) {
      alert(data.reason)
    }
  }
  
  return (
    <>
    <SideMenu>
    <ContainerCard title="Producto" subtitle="Agregar un nuevo" action={
      <div className="">
      <Button onClick={(e) => { saveProduct(e) }}>Guardar</Button>
      <Button onClick={(e) => { publishProduct(e) }} className="mx-1">Publicar</Button>
      </div>
    }>
    </ContainerCard>
    
    <Title className="mt-4">Informacion basica del producto</Title>
    <Card className="mt-4">
      <Subtitle className="mb-4">Titulo del producto</Subtitle>
      <TextInput name="productName" value={product.title} placeholder="Product name" />
      <Subtitle className="mt-4">Descripcion del producto</Subtitle>
      <TextInput name="productDescription" value={product.description} className="my-2" placeholder="Product description" />
      
      <Grid direction="row" numItems={1} numItemsSm={2} numItemsMd={2} numItemsLg={2} className="gap-4 my-4">
        <div>
          <Subtitle>Costo promedio</Subtitle>
          <TextInput icon={CurrencyDollarIcon} value={ product.variants.reduce((a, b) => a + b.price, 0) / product.variants.length } placeholder="$ 0.00" readOnly disabled />
        </div>
        
        <div>
          <Subtitle>Venta promedio</Subtitle>
          <TextInput icon={CurrencyDollarIcon} value={ product.variants.reduce((a, b) => a + b.salePrice, 0) / product.variants.length } placeholder="$ 0.00" readOnly disabled />
        </div>              
      </Grid>
      
      <Subtitle className="mt-4 mb-2">Categoria</Subtitle>
      <Flex className="gap-2">
        <CategorySelector callback={categoryBuilder} name="category_selector" value={category} setValue={setCategory} />
        <Button onClick={(e) => createCategory(e)}>Agregar Categoria</Button>
      </Flex>
      
      <Subtitle className="mt-6">Variants</Subtitle>
      <Card>
      <Button onClick={(e) => createVariant(e)}>Agregar Variante</Button>
      <Grid  direction="row" numItems={2} numItemsSm={2} numItemsMd={3} numItemsLg={4} className="gap-4 mt-8 items-center justify-center">
        {product.variants.map((variant, index) => {
          return (
            <Card className="w-48 h-48" decoration="bottom" decorationColor={ variant.availability === true && variant.stock > 0 ? "green" : "rose"}>
              <div className="relative w-full h-full overflow-hidden">
                <Icon icon={TrashIcon} 
                onClick={(e) => { deleteProductVariant(e, index) }}
                className="absolute z-50 bottom-0 right-1 bg-slate-50 rounded-full hover:bg-slate-200 cursor-pointer" />
                
                <div className="absolute z-30 w-full h-full items-center justify-center text-center opacity-80">
                  <Subtitle className="bg-slate-400">{ variant.name }</Subtitle>
                </div>
                { variant.images.length > 0 && (
                  <img key={index} src={"data:" + variant.images[0].type + ";base64," + variant.images[0].dat} className="relative z-10 rounded" />
                )}
              </div>
            </Card>)
          })}
        
          {product.variants.length < 1 && (
            <Title>No tienes aun variantes</Title>
          )}  
        </Grid>
      </Card>
    </Card>
          
    <Title className="my-4">Finanzas</Title>
    <Card>
      <BarChart
        data={ product.variants.map((variant) => {
            return {
              label: variant.name,
              "Costo": variant.price,
              "Venta": variant.salePrice,
              "Ganancia": variant.salePrice - variant.price,
              "Ventas": 0
            }
          })}
        index="label"
        categories={["Costo", "Venta", "Ganancia", "Ventas"]}
        colors={["rose", "green", "yellow", "purple", "red"]} 
        showXAxis={true}
        layout="vertical"
        valueFormatter={dataFormatter}
      />

      <Table>
        <TableHead>
          <TableHeaderCell>Variante</TableHeaderCell>
          <TableHeaderCell>Costo</TableHeaderCell>
          <TableHeaderCell>Inventario</TableHeaderCell>
          <TableHeaderCell>∑ Costo</TableHeaderCell>
          <TableHeaderCell>∑ IVA</TableHeaderCell>
          <TableHeaderCell>Ventas</TableHeaderCell>
        </TableHead>
        <TableBody>
          {product.variants.map((variant) => {
            return (
              <TableRow>
                <TableCell>{variant.name}</TableCell>
                <TableCell>{dataFormatter(variant.price)}</TableCell>
                <TableCell>{variant.stock}</TableCell>
                <TableCell>{dataFormatter(variant.price * variant.stock)}</TableCell>
                <TableCell>{dataFormatter(variant.price * variant.stock * 0.16)}</TableCell>
                <TableCell>(0) $ 0.00</TableCell>
              </TableRow>
            )})}
        </TableBody>
      </Table>
    </Card>
  </SideMenu>
  </>
  );
}

export default CreateProduct;