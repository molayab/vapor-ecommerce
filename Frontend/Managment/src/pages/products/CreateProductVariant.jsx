import { useState } from "react";
import SideMenu from "../../components/SideMenu";
import { API_URL } from "../../App";
import { useParams } from "react-router-dom";
import { useNavigate } from "react-router-dom";
import { Button } from "@tremor/react";
import ContainerCard from "../../components/ContainerCard";
import { SaveAsIcon } from "@heroicons/react/solid";
import ProductVariantForm from "./_components/ProductVariantForm";

function CreateProductVariant() {
  let { id } = useParams()
  const navigate = useNavigate()
  const [resources, setResources] = useState([])
  const [isLoading, setIsLoading] = useState(false)
  const [variant, setVariant] = useState({
        name: "",
        sku: "",
        price: 0,
        salePrice: 0,
        stock: 0,
        availability: true,
        tax: 0,
        shippingCost: 0
  })
  // const variant = useVariant(pid, id)

    const addImages = async (e) => {
        const images = e.target.files
        let r = []
        for (let i = 0; i < images.length; i++) {
            const file = await readAsDataURL(images[i])
            console.log(file)
            r.push({
                dat: await toBase64(images[i]),
                ext: file.ext,
                name: file.name,
                size: file.size
            })
        }
        setResources((old) => [...old, ...r])
    }

  const remoteRemoveImage = async (index) => {
    const response = await fetch(API_URL + '/products/' + pid + '/variants/' + id + '/images', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: images[index]
    })

    const data = await response.json()
    if (data.error) {
        alert(data.reason)
    }
  }

  

  const createVariant = async (e) => {
    /*e.preventDefault()

    setIsLoading(true)
    const a = useCreateVariant(pid, {
      name: name,
      sku: skuCode.sku,
      price: parseFloat(price),
      salePrice: parseFloat(salePrice),
      stock: parseInt(stock),
      availability: availability === "true" ? true : false,
      tax: parseFloat(tax),
      shippingCost: parseFloat(shippingCost)
    })

    if (a === null) {
      console.log("Loading...")
    } else if (a.error) {
      alert(a.reason)
    } else {
      navigate(`/products/${pid}`);
    }
    setIsLoading(false)*/
  }

  return (
    <>
      <SideMenu>
        <ContainerCard title={id} subtitle="Agregar una variante a" action={
          <div className="">
            <Button icon={SaveAsIcon} onClick={(e) => {  }} className="mx-1" loading={isLoading}>Agregar</Button>
          </div>
          }>
        </ContainerCard>

        <ProductVariantForm productVariant={variant} setVariant={setVariant} resources={resources} imageHandler={addImages} />
      </SideMenu>
    </>
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
  return new Promise((resolve, reject)=>{
      let fileReader = new FileReader()
      fileReader.onload = function(){
          return resolve({dat: fileReader.result, name: file.name, size: file.size, ext: file.type})
      }
      fileReader.readAsDataURL(file)
  })
}