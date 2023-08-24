import React, { useEffect, useState } from "react"

import { useCategories } from "../../../hooks/categories"
import { RES_URL } from "../../../App"
import { Button, Card, Flex, Grid, Icon, SearchSelect, SearchSelectItem, SelectItem, Subtitle, Table, TableBody, TableCell, TableHead, TableHeaderCell, TableRow, TextInput, Title } from "@tremor/react"
import { CurrencyDollarIcon, TrashIcon } from "@heroicons/react/solid"
import { BarChart } from "@tremor/react"
import { dataFormatter } from "../../../helpers/dateFormatter"
import Loader from "../../../components/Loader"
import { createCategory } from "../../../components/services/categories"

function ProductForm({product, setProduct, onSave}) {
    let categories = useCategories()
    let [localCategories, setLocalCategories] = useState(null)
    let [errors, setErrors] = useState({})

    useEffect(() => {
        setLocalCategories(categories)
    }, [categories])
    
    product = {...product}
    if (product.variants === undefined) {
        product.variants = []
    }

    // Show loader if categories are not loaded
    if (categories === null || localCategories === null) {
        return <Loader />
    }

    const addCategory = async (e) => {
        let name = prompt("Nombre de la categoria:")
        if (name === null || name === "") {
            return alert("Category name is required")
        }

        const id = await createCategory(name)
        console.log(id)
        if (localCategories === null) {
            setLocalCategories([{ id: id, name: name }])
        } else {
            setLocalCategories([...localCategories, { id: id, name: name }])
        }
    }

    const validateProduct = () => {
        setErrors({})

        if (product.title === undefined || product.title === "") {
            setErrors({ title: "Product title is required" })
        }

        if (product.description === undefined || product.description === "") {
            setErrors({ description: "Product description is required" })
        }

        if (product.category === undefined || product.category === "") {
            setErrors({ category: "Product category is required" })
        }
    }

    const addVariant = () => {
        validateProduct()
        onSave()
    }

    return (
        <>
        <Title className="mt-4">Informacion basica del producto</Title>
        <Card className="mt-4">
        <Subtitle className="mb-4">Titulo del producto</Subtitle>
        <TextInput 
            error={errors.title}
            errorMessage={errors.title}
            name="productName" 
            value={product.title} 
            onChange={ (e) => setProduct({ ...product, title: e.target.value }) } 
            className="my-2" 
            placeholder="Vestido de baño completo" />
        <Subtitle className="mt-4">Descripcion del producto</Subtitle>
        <TextInput 
            name="productDescription" 
            error={errors.description}
            errorMessage={errors.description}
            value={product.description} 
            onChange={ (e) => setProduct({ ...product, description: e.target.value }) } 
            className="my-2" 
            placeholder="Hermoso vestido de baño completo para dama" />
        
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
        <Flex className="gap-2" error={errors.category} errorMessage={errors.category}>
            <SearchSelect onChange={ (e) => setProduct({ ...product, category: e }) } value={product.category} className="w-full">
                {localCategories.map((category) => {
                    return (
                        <SearchSelectItem key={category.id} value={category.id}>{category.title}</SearchSelectItem>
                    )
                })}
            </SearchSelect>
            <Button onClick={(e) => { addCategory(e) }}>Agregar Categoria</Button>
        </Flex>
        
        <Subtitle className="mt-6">Variants</Subtitle>
        <Card>
        <Button onClick={(e) => addVariant(e)}>Agregar Variante</Button>
        <Grid  direction="row" numItems={2} numItemsSm={2} numItemsMd={3} numItemsLg={4} className="gap-4 mt-8 items-center justify-center">
            {product.variants.map((variant, index) => {
            return (
                <Card className="w-48 h-48" decoration="bottom" decorationColor={ variant.availability === true && variant.stock > 0 ? "green" : "rose"}>
                <div className="relative w-full h-full overflow-hidden">
                    <Icon icon={TrashIcon} 
                    onClick={(e) => { deleteProductVariant(e, index) }}
                    className="absolute z-50 bottom-0 right-1 bg-slate-50 rounded-full hover:bg-slate-200 cursor-pointer" />
                    
                    <div className="absolute z-30 w-full h-full items-center justify-center text-center opacity-80 cursor-pointer">
                    <Subtitle onClick={(e) => { navigate("/products/" + id + "/variants/" + variant.id + "/edit") }} className="bg-slate-400">{ variant.name }</Subtitle>
                    </div>
                    { variant.images.length > 0 && (
                    <img 
                        key={index} 
                        src={RES_URL + variant.images[0]} 
                        className="relative z-10 rounded" />
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
                "Ventas": (variant.salePrice - variant.price) * variant.sales.length,
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
            {product.variants !== undefined ? product.variants.map((variant) => {
                return (
                <TableRow>
                    <TableCell>{variant.name}</TableCell>
                    <TableCell>{dataFormatter(variant.price)}</TableCell>
                    <TableCell>{variant.stock}</TableCell>
                    <TableCell>{dataFormatter(variant.price * variant.stock)}</TableCell>
                    <TableCell>{dataFormatter(variant.price * variant.stock * 0.16)}</TableCell>
                    <TableCell>({ variant.sales.length }) $ { variant.sales.map((sale) => sale.total).reduce((a, b) => a + b, 0) }</TableCell>
                </TableRow>
                )}) : <Title>No hay variantes</Title>}
            </TableBody>
        </Table>
    </Card>
    </>)
}

export default ProductForm