import SideMenu from "../../components/SideMenu";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { API_URL, RES_URL } from "../../App";
import ContainerCard from "../../components/ContainerCard";
import { BarChart, Button, Callout, Card, Flex, Grid, Icon, Subtitle, Table, TableBody, TableCell, TableHead, TableHeaderCell, TableRow, TextInput, Title } from "@tremor/react"
import { ExclamationCircleIcon, EyeIcon, EyeOffIcon, SaveIcon, TrashIcon } from "@heroicons/react/solid";
import { ArrowSmUpIcon, CurrencyDollarIcon } from "@heroicons/react/outline";
import { useParams } from "react-router-dom";
import { useDeleteProduct, useProduct } from "../../hooks/products";
import { useCreateCategory } from "../../hooks/categories";
import Loader from "../../components/Loader";
import ProductForm from "./_components/ProductForm";
import { createProduct, updateProduct } from "../../components/services/products";

function UpdateProduct() {
    const navigate = useNavigate()
    const { id } = useParams()
    
    const product = useProduct(id)
    const [isLoading, setIsLoading] = useState(false)
    const [localProduct, setLocalProduct] = useState(product)
    const [errors, setErrors] = useState({})
    const [isPublished, setIsPublished] = useState(false)
    if (product === null) {
        return <Loader />
    }

    const deleteProduct = async (e) => {
        e.preventDefault()

        if (useDeleteProduct(id)) {
            navigate("/products")
        }
    }
  
    const updateVariant = async () => {
        if (localProduct) {
            setErrors({})
            setIsLoading(true)
            let response = await updateProduct(id, { ...localProduct, isPublished: isPublished })
            let data = await response.json()
            if (data.id) {
                setIsLoading(false)
                navigate("/products/" + data.id + "/variant")
            }
        } else {
            setErrors({ title: "Product information is required" })
        }
    }

    return (
        <SideMenu>
            <ContainerCard title="Producto" subtitle="Editar el producto" action={
            <div className="">
                <Button 
                    isLoading={isLoading}
                    onClick={(e) => {  }} 
                    icon={SaveIcon} 
                    variant="secondary">Guardar</Button>
                <Button 
                    isLoading={isLoading}
                    onClick={ (e) => deleteProduct(e) } 
                    className="mx-1"
                    color="rose" 
                    icon={TrashIcon}>Borrar Producto</Button>
                <Button
                    isLoading={isLoading}
                    color={ isPublished ? "rose" : "green" }
                    onClick={(e) => setIsPublished(!isPublished)}
                    icon={ !isPublished ? EyeIcon : EyeOffIcon }
                    className="mx-1">{ isPublished ? "Despublicar" : "Publicar" }</Button>
            </div>}>
            </ContainerCard>

            { errors.title && 
                <Callout color="rose" className="mt-2" title="Error" icon={ExclamationCircleIcon}>
                    { errors.title }
                </Callout>
            }
            
            <ProductForm product={localProduct} setProduct={setLocalProduct} onSave={updateVariant} />
        </SideMenu>
    )
}

export default UpdateProduct