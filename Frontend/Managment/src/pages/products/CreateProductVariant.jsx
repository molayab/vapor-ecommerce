import { useEffect, useState } from "react";
import SideMenu from "../../components/SideMenu";
import { API_URL, RES_URL } from "../../App";
import { useParams } from "react-router-dom";
import { useNavigate } from "react-router-dom";
import Barcode from "react-barcode";
import { Button, Card, Flex, Grid, Icon, List, ListItem, Metric, NumberInput, Select, SelectItem, Subtitle, TextInput, Title } from "@tremor/react";
import ContainerCard from "../../components/ContainerCard";
import { CurrencyDollarIcon, DocumentRemoveIcon, SaveAsIcon, TrashIcon, TruckIcon, VariableIcon } from "@heroicons/react/solid";

function CreateProductVariant() {
  let { id, pid } = useParams();
  const navigate = useNavigate();

  const fixedPaymentCost = 500;
  const paymentFee = 0.03;

  const [name, setName] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [availability, setAvailability] = useState("false");
  const [stock, setStock] = useState(1);
  const [price, setPrice] = useState(1);
  const [salePrice, setSalePrice] = useState(1);
  const [skuCode, setSkuCode] = useState({sku: '000000'});
  const [tax, setTax] = useState(0)
  const [shippingCost, setShippingCost] = useState(0)
  const [images, setImages] = useState([])

  const fetchProductVariant = async (productId, variantId) => {
    const response = await fetch(API_URL + '/products/' + productId + '/variants/' + variantId, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' }
    })

    const data = await response.json()
    if (data.id) {
      const regex = /t256_/g

      setName(data.name)
      setAvailability(data.availability)
      setStock(data.stock)
      setPrice(data.price)
      setSalePrice(data.salePrice)
      setTax(data.tax)
      setShippingCost(data.shippingCost)
      setImages(data.images.filter((image) => {
        // Filter thumbnails with the prefix "t<size>_"
        return image.match(regex)
      }))

    } else if (data.error) {
      alert(data.reason)
    }
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

  const requestSkuCode = async () => {
    const response = await fetch(API_URL + '/products/new/variants/sku', {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' }
    })
    setSkuCode(await response.json())
  }

  useEffect(() => {
    requestSkuCode()
  }, [])

  useEffect(() => {
    if (id && pid) {
      fetchProductVariant(pid, id)
    }
  }, [id])

  const addImages = async (e) => {
    setIsLoading(true)
    const images = document.querySelector('input[name="variantFiles[]"]').files
    let resources = []
    for (let i = 0; i < images.length; i++) {
      const file = await readAsDataURL(images[i])
      resources.push({
        dat: await toBase64(images[i]),
        ext: file.type,
        name : file.name,
        size : file.size
      })
    }
    
    console.log(resources)
    setImages((old) => [...old, ...resources])

    // Create product in backend and get id
    const variant = {
      name: name,
      sku: skuCode.sku,
      price: parseFloat(price),
      salePrice: parseFloat(salePrice),
      stock: parseInt(stock),
      availability: availability === "true" ? true : false,
      tax: parseFloat(tax),
      shippingCost: parseFloat(shippingCost)
    }

    let _id = id ? "/" + id : ""
    let response = await fetch(API_URL + '/products/' + pid + '/variants' + _id, {
      method: id ? 'PATCH' : 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(variant)
    })

    let data = await response.json();
    if (data.id) {
      // Create images in backend
      response = await fetch(API_URL + '/products/' + pid + '/variants/' + id + '/images/multiple', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(resources)
      })
    } else if (data.error) {
      alert(data.reason)
    }
    setIsLoading(false)
  }

  const onSubmit = async (e) => {
    setIsLoading(true)

    e.preventDefault()
    const variant = {
      name: name,
      sku: skuCode.sku,
      price: parseFloat(price),
      salePrice: parseFloat(salePrice),
      stock: parseInt(stock),
      availability: availability === "true" ? true : false,
      tax: parseFloat(tax),
      shippingCost: parseFloat(shippingCost)
    }

    let _id = id ? "/" + id : ""
    const response = await fetch(API_URL + '/products/' + pid + '/variants' + _id, {
      method: id ? 'PATCH' : 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(variant)
    })

    const data = await response.json();
    if (data.id) {
      navigate(`/products/${pid}`);
    } else if (data.error) {
      alert(data.reason);
    }

    setIsLoading(false)
  }

  return (
    <>
      <SideMenu>
        <ContainerCard title={pid} subtitle="Agregar una variante a" action={
          <div className="">
            <Button icon={SaveAsIcon} onClick={(e) => { onSubmit(e) }} className="mx-1" loading={isLoading}>
              { id ? "Guardar" : "Agregar"}
            </Button>
          </div>
          }>
        </ContainerCard>

        <Card className="mt-4 pb-14">
          <div className="relative">
            <div className="absolute right-2">
              <Barcode value={skuCode.sku} height={10} margin={1} format="CODE128" />
            </div>
            <div className="relative top-10">
              <Title>Agregar variante del producto</Title>
              <Subtitle>Las variantes son las diferentes versiones de su producto. Por ejemplo, si vende camisetas, puede tener una variante para el tamaño y el color.</Subtitle>

              <Subtitle className="mt-8">Nombre de la variant</Subtitle>
              <TextInput 
                type="text" 
                value={name}
                onValueChange={setName} 
                placeholder="'Tamaño - Color', 'Capacidad - Titulo', etc..." 
                className="border border-gray-400 px-2 py-1 rounded w-full" />
              <Subtitle className="mt-2">SKU</Subtitle>
              <TextInput 
                type="text"
                name="variantSku"
                placeholder="SKU: Numero unico de identificacion de la variante"
                value={skuCode.sku}
                onValueChange={(e) => setSkuCode({sku: e})}
                className="border border-gray-400 px-2 py-1 rounded w-full" />

              <Flex className="mt-4">
                <div className="w-full">
                  <Subtitle><b>Costo</b> <i>(lo que te cuesta)</i></Subtitle>
                  <NumberInput icon={CurrencyDollarIcon} value={price} onValueChange={setPrice} placeholder="0.00" className="border border-gray-400 px-2 py-1 rounded w-full" />
                </div>
                <div className="w-full ml-4">
                  <Subtitle><b>Precio</b> <i>(lo que le cobras)</i></Subtitle>
                  <NumberInput icon={CurrencyDollarIcon} value={salePrice} onValueChange={setSalePrice} placeholder="0.00" className="border border-gray-400 px-2 py-1 rounded w-full" />
                </div>
              </Flex>
              <Flex className="mt-4">
                <div className="w-full">
                  <Subtitle><b>Stock</b> <i>(cantidad disponible)</i></Subtitle>
                  <NumberInput icon={TruckIcon} value={stock} onValueChange={setStock} placeholder="Variant stock" className="border border-gray-400 px-2 py-1 rounded w-full" />
                </div>
                <div className="w-full ml-4">
                  <Subtitle>Disponibilidad</Subtitle>
                  <Select value={availability} onValueChange={setAvailability}>
                    <SelectItem value="true">Disponible</SelectItem>
                    <SelectItem value="false">No disponible</SelectItem>
                  </Select>
                </div>
              </Flex>

              <Flex className="mt-4">
                <div className="w-full">
                  <Subtitle><b>% IVA</b> <i>(Impuesto Legal)</i></Subtitle>
                  <NumberInput icon={VariableIcon} placeholder="19 %" value={tax * 100} onValueChange={(e) => setTax(e / 100)} className="border border-gray-400 px-2 py-1 rounded w-full" />
                </div>
                <div className="w-full ml-4">
                  <Subtitle><b>Envio</b> <i>(Costo Envio)</i></Subtitle>
                  <NumberInput icon={CurrencyDollarIcon} placeholder="$ 0.00" value={shippingCost} onValueChange={setShippingCost} className="border border-gray-400 px-2 py-1 rounded w-full" />
                </div>
              </Flex>

              <Flex className="my-4">
                <div className="w-80">
                  <Subtitle>Porcentaje de ganancia</Subtitle>
                  <Metric> { (salePrice - price) / price * 100 }% </Metric>
                </div>
                <div>
                  <Subtitle>Ganancia Neta</Subtitle>
                  <Metric>$ { salePrice - price - (salePrice * tax) - (salePrice * paymentFee) - fixedPaymentCost - shippingCost } </Metric>
                </div>
              </Flex>
              <Grid numItems={1} numItemsSm={2} className="gap-8">
                <Card>
                  <Metric>Imagenes</Metric>
                  <Subtitle className="mt-1">Las imagenes son importantes para que los clientes puedan ver el producto, recuerda elegir imagenes de buena calidad, buena iluminacion y que muestren el producto de la mejor manera posible. La primera imagen de la lista sera la imagen principal del producto.</Subtitle>
                  <Title className="mt-4">Las imagenes deben ser de formato JPG, JPEG o PNG.</Title>
                  <input name="variantFiles[]" onChange={addImages} accept=".gif,.jpg,.jpeg,.png" type="file" className="border border-gray-400 px-2 py-1 rounded w-full bg-slate-300" multiple />
                </Card>

                <List className="w-full">
                  <ListItem>
                    <span>Ganancia</span>
                    <span>$ { salePrice - price - shippingCost } </span>
                  </ListItem>
                  <ListItem>
                    <span>Costo de pasarela pagos</span>
                    <span>$ { (salePrice * paymentFee) + fixedPaymentCost }  </span>
                  </ListItem>
                  <ListItem>
                    <span>Costo de envio</span>
                    <span>$ { shippingCost } </span>
                  </ListItem>
                  <ListItem>
                    <span>Impuesto</span>
                    <span>$ { salePrice * tax } </span>
                  </ListItem>
                  <ListItem>
                    <span>Ganancia Neta</span>
                    <span>$ { salePrice - price - (salePrice * tax) } </span>
                  </ListItem>
                  <ListItem>
                    <span>Ganancia Bruta</span>
                    <span>$ { salePrice - price }</span>
                  </ListItem>
                </List>
              </Grid>
            </div>
          </div>
        </Card>

        <Card className="mt-4" decoration="bottom" decorationColor="blue">
          
          <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6">
            { images.map((image, index) => {
              if (image.dat === undefined) {
                return (
                  <div className="relative w-48">
                    <div className="absolute right-0 bottom-0 w-full z-10 bg-slate-300 rounded opacity-30 hover:opacity-100">
                      <Icon icon={TrashIcon} className="w-6 h-6 cursor-pointer" onClick={() => {
                        setImages((old) => {
                          let newImages = [...old]
                          newImages.splice(index, 1)
                          remoteRemoveImage(index)
                          return newImages
                        })
                      }} />
                    </div>
                    <div className="relative z-0">
                      <img key={index} src={RES_URL + image} className="w-48 h-48 object-cover rounded" />
                    </div>
                  </div>
                )
              } else {
                return (
                  <div className="relative w-48">
                    <div className="absolute right-0 bottom-0 w-full z-10 bg-slate-300 rounded opacity-30 hover:opacity-100">
                      <Icon icon={TrashIcon} className="w-6 h-6 cursor-pointer" onClick={() => {
                        setImages((old) => {
                          let newImages = [...old]
                          newImages.splice(index, 1)
                          return newImages
                        })
                      }} />
                    </div>
                    <div className="relative z-0">
                      <img key={index} src={"data:" + image.type + ";base64," + image.dat} className="w-48 h-48 object-cover rounded" />
                    </div>
                  </div>
                )
              }
              
            })}
          </div>
        </Card>
      </SideMenu>
    </>
  )
}

export function readAsDataURL(file) {
  return new Promise((resolve, reject)=>{
    let fileReader = new FileReader();
    fileReader.onload = function(){
      return resolve({data:fileReader.result, name:file.name, size: file.size, type: file.type});
    }
    fileReader.readAsDataURL(file);
  })
}

export default CreateProductVariant;
export function toBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      let encoded = reader.result.toString().replace(/^data:(.*,)?/, '');
      if ((encoded.length % 4) > 0) {
        encoded += '='.repeat(4 - (encoded.length % 4));
      }
      resolve(encoded);
    };
    reader.onerror = error => reject(error);
  });
}