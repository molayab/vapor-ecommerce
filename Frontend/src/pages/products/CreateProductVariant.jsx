import { useState } from "react"
import { useParams, useNavigate } from "react-router-dom"
import { Button, Callout } from "@tremor/react"
import { ExclamationCircleIcon, SaveAsIcon } from "@heroicons/react/solid"
import { createVariant } from "../../components/services/variants"
import ContainerCard from "../../components/ContainerCard"
import ProductVariantForm from "./_components/ProductVariantForm"
import SideMenu from "../../components/SideMenu"
import { uploadMultipleImages } from "../../components/services/images"

function CreateProductVariant() {
    let { id } = useParams()
    const [resources, setResources] = useState([])
    const [isLoading, setIsLoading] = useState(false)
    const [errors, setErrors] = useState({})
    const [variant, setVariant] = useState({
        name: "",
        sku: "",
        price: 0,
        salePrice: 0,
        stock: 1,
        availability: true,
        tax: 0,
        shippingCost: 0
    })

    const addImages = async (e) => {
        const images = e.target.files
        let r = []
        for (let i = 0; i < images.length; i++) {
            const file = await readAsDataURL(images[i])
            r.push({
                dat: await toBase64(images[i]),
                ext: file.ext,
                name: file.name,
                size: file.size
            })
        }
        setResources((old) => [...old, ...r])
    }

    const create = async (e) => {
        setIsLoading(true)
        let response = await createVariant(id, { ...variant, images: resources })
        let data = await response.json()
        if (data.id) {
            // Add images
            let toAdd = resources.filter((i) => i.dat !== null)
            if (toAdd.length > 0) {
                let response = await uploadMultipleImages(pid, id, toAdd)
                if (response.status !== 200) {
                    setErrors({ title: "Error al subir las imagenes" })
                } else if (toAdd.length > 0) {
                    // setNotifications({ title: "Imagenes subidas correctamente" })
                }
            }

            setIsLoading(false)
            // setNotifications({ title: "Variante creada correctamente" })
        } else {
            setErrors({ title: "Error al crear la variante" })
            setIsLoading(false)
        }
    }

    return (
        <SideMenu>
            <ContainerCard title={id} subtitle="Agregar una variante a" action={
                <div className="">
                    <Button icon={SaveAsIcon} onClick={create} className="mx-1" loading={isLoading}>Agregar</Button>
                </div>
            }>
            </ContainerCard>

            { errors.title &&
                <Callout color="rose" className="mt-2" title="Error" icon={ExclamationCircleIcon}>
                    { errors.title }
                </Callout>
            }

            <ProductVariantForm 
                productVariant={variant} 
                setVariant={setVariant} 
                resources={resources} 
                setResources={setResources} 
                imageHandler={addImages} />
        </SideMenu>
    )
}

export default CreateProductVariant
export function toBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.readAsDataURL(file)
        reader.onload = () => {
            let encoded = reader.result.toString().replace(/^data:(.*,)?/, '')
            if ((encoded.length % 4) > 0) {
                encoded += '='.repeat(4 - (encoded.length % 4))
            }
            resolve(encoded)
        }
        reader.onerror = error => reject(error);
    })
}
export function readAsDataURL(file) {
    return new Promise((resolve, reject) => {
        let fileReader = new FileReader()
        fileReader.onload = function() {
            return resolve({dat: fileReader.result, name: file.name, size: file.size, ext: file.type})
        }
        fileReader.readAsDataURL(file)
    })
}