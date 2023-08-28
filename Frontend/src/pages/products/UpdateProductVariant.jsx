import { useNavigate, useParams } from "react-router-dom";
import { updateVariant } from "../../components/services/variants";
import { useVariant } from "../../hooks/variants";
import { useEffect, useState } from "react";
import { Button } from "@tremor/react";
import { SaveAsIcon } from "@heroicons/react/solid";
import { readAsDataURL, toBase64 } from "./CreateProductVariant";
import Loader from "../../components/Loader";
import ContainerCard from "../../components/ContainerCard";
import SideMenu from "../../components/SideMenu";
import ProductVariantForm from "./_components/ProductVariantForm";
import { removeImage, uploadMultipleImages } from "../../components/services/images";

function UpdateProductVariant() {
    const { pid, id } = useParams()
    const variant = useVariant(pid, id)
    
    const [isLoading, setIsLoading] = useState(false)
    const [localVariant, setLocalVariant] = useState(variant)
    const [localResources, setLocalResources] = useState(null)

    let variantImages = []
    let resourcesImages = []
    
    const update = async (e) => {
        setIsLoading(true)
        let response = await updateVariant(pid, id, {...localVariant, 
            images: localResources.filter((i) => i.dat), 
            availability: localVariant.availability || false, 
            isAvailable: localVariant.availability})
            
        let data = await response.json()
        if (data.id) {
            let toRemove = []
            let toAdd = []

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

            console.log(toRemove)
            console.log(toAdd)

            // Remove images
            for (let i = 0; i < toRemove.length; i++) {
                const image = toRemove[i]
                const response = await removeImage(pid, id, image.url)

                if (response.status === 200) {
                    console.log("DELETED: " + image)
                } else {
                    console.log("NOT DELETED: " + image)
                    alert("Error al eliminar la imagen " + image)
                }
            }

            // Add images
            let response = await uploadMultipleImages(pid, id, toAdd.filter((i) => i.dat !== null))
            if (response.status !== 200) {
                console.log("ERROR: " + response)
                alert("Error al subir las imágenes")
            } else {
                console.log("IMAGES UPLOADED")
            }

            setIsLoading(false)
            //navigate("/products/" + pid)
        } else {
            setIsLoading(false)
        }
    }

    console.log(resourcesImages)
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
            <ContainerCard title="Update Product Variant" action={
                <div className="">
                    <Button icon={SaveAsIcon} onClick={(e) => {  update(e) }} className="mx-1" loading={isLoading}>Guardar</Button>
                </div>
            }>
            </ContainerCard>

            <ProductVariantForm 
                productVariant={{...localVariant, images: localResources}} 
                setVariant={setLocalVariant} 
                resources={localResources}
                setResources={setLocalResources}
                imageHandler={addImages} />
        </SideMenu>
    )
}

export default UpdateProductVariant