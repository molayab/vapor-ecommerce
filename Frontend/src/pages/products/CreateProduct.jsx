import SideMenu from "../../components/SideMenu"
import ContainerCard from "../../components/ContainerCard"
import Loader from "../../components/Loader"
import ProductForm from "./_components/ProductForm"
import { useNavigate } from "react-router-dom"
import { useState } from "react"
import { Button, Callout } from "@tremor/react"
import { ExclamationCircleIcon, EyeIcon, EyeOffIcon, SaveIcon } from "@heroicons/react/solid"
import { createProduct } from "../../components/services/products"

function CreateProduct() {
    const navigate = useNavigate()
    const product = {
        title: "",
        description: "",
        category: ""
    }

    const [isLoading, setIsLoading] = useState(false)
    const [localProduct, setLocalProduct] = useState(product)
    const [errors, setErrors] = useState({})
    const [isPublished, setIsPublished] = useState(true)

    if (product === null) {
        return <Loader />
    }
  
    const createVariant = async () => {
        if (localProduct) {
            setErrors({})
            setIsLoading(true)
            
            let response = await createProduct({ ...localProduct, isPublished: isPublished, category: localProduct.category.id })
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
            <ContainerCard title="Producto" subtitle="Agregar un nuevo" action={
            <div className="">
                <Button
                    isLoading={isLoading}
                    variant="secondary"
                    color={ isPublished ? "rose" : "green" }
                    onClick={(e) => setIsPublished(!isPublished)}
                    icon={ !isPublished ? EyeIcon : EyeOffIcon }
                    className="mx-1">{ isPublished ? "Despublicar" : "Publicar" }</Button>
                <Button 
                    isLoading={isLoading}
                    onClick={(e) => {  }} 
                    icon={SaveIcon} 
                    variant="secondary">Guardar</Button>
            </div>}>
            </ContainerCard>

            { errors.title && 
                <Callout color="rose" className="mt-2" title="Error" icon={ExclamationCircleIcon}>
                    { errors.title }
                </Callout>
            }
            
            <ProductForm product={localProduct} setProduct={setLocalProduct} onSave={createVariant} />
        </SideMenu>
    )
}

export default CreateProduct