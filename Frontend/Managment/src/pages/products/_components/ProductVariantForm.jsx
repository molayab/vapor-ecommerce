import React, { useEffect, useState } from 'react'
import { Card, Flex, Grid, Icon, List, ListItem, Metric, NumberInput, Select, SelectItem, Subtitle, TextInput, Title } from "@tremor/react";
import { CurrencyDollarIcon, TrashIcon, TruckIcon, VariableIcon } from "@heroicons/react/solid";
import { useRequestVariantSKU } from '../../../hooks/variants';
import Loader from '../../../components/Loader';
import { dataFormatter } from '../../../helpers/dateFormatter';

const fixedPaymentCost = 500;
const paymentFee = 0.03;

function ProductVariantForm({ productVariant, setVariant, resources, imageHandler }) {
    const skuCode = useRequestVariantSKU()
    const [sku, setSku] = useState(null)
    
    useEffect(() => {
        setSku(skuCode)
    }, [skuCode])

    if (skuCode === null) {
        return <Loader />
    }

    return (
        <>
            <Card className="mt-4 pb-14">
            <div className="relative">
                <div className="absolute right-2">
                </div>
                <div className="relative">
                <Title>Agregar variante del producto</Title>
                <Subtitle>Las variantes son las diferentes versiones de su producto. Por ejemplo, si vende camisetas, puede tener una variante para el tamaño y el color.</Subtitle>
                
                <Subtitle className="mt-8">Nombre de la variant</Subtitle>
                <TextInput 
                    type="text" 
                    value={productVariant.title}
                    onChange={(e) => setVariant({ ...productVariant, name: e })}
                    placeholder="'Tamaño - Color', 'Capacidad - Titulo', etc..." 
                    className="border border-gray-400 px-2 py-1 rounded w-full" />
                <Subtitle className="mt-2">SKU</Subtitle>
                <TextInput 
                    type="text"
                    name="variantSku"
                    placeholder="SKU: Numero unico de identificacion de la variante"
                    value={ sku ? sku.sku : ""}
                    onChange={(e) => setSku(e)}
                    className="border border-gray-400 px-2 py-1 rounded w-full" />

                <Flex className="mt-4">
                    <div className="w-full">
                    <Subtitle><b>Costo</b> <i>(lo que te cuesta)</i></Subtitle>
                    <NumberInput 
                        icon={CurrencyDollarIcon} 
                        value={productVariant.price} 
                        onValueChange={(e) => setVariant({ ...productVariant, price: e })}
                        placeholder="0.00" 
                        className="border border-gray-400 px-2 py-1 rounded w-full" />
                    </div>
                    <div className="w-full ml-4">
                    <Subtitle><b>Precio</b> <i>(lo que le cobras)</i></Subtitle>
                    <NumberInput 
                        icon={CurrencyDollarIcon} 
                        value={productVariant.salePrice} 
                        onValueChange={(e) => setVariant({ ...productVariant, salePrice: e })}
                        placeholder="0.00" 
                        className="border border-gray-400 px-2 py-1 rounded w-full" />
                    </div>
                </Flex>
                <Flex className="mt-4">
                    <div className="w-full">
                    <Subtitle><b>Stock</b> <i>(cantidad disponible)</i></Subtitle>
                    <NumberInput 
                        icon={TruckIcon} 
                        value={productVariant.stock} 
                        onValueChange={(e) => setVariant({ ...productVariant, stock: e })}
                        placeholder="Variant stock" 
                        className="border border-gray-400 px-2 py-1 rounded w-full" />
                    </div>
                    <div className="w-full ml-4">
                    <Subtitle>Disponibilidad</Subtitle>
                    <Select 
                        value={productVariant.availability} 
                        onValueChange={ (e) => setVariant({ ...productVariant, availability: e }) }>

                        <SelectItem value="true">Disponible</SelectItem>
                        <SelectItem value="false">No disponible</SelectItem>
                    </Select>
                    </div>
                </Flex>

                <Flex className="mt-4">
                    <div className="w-full">
                    <Subtitle><b>% IVA</b> <i>(Impuesto Legal)</i></Subtitle>
                    <NumberInput 
                        icon={VariableIcon} 
                        placeholder="19 %" 
                        value={productVariant.tax * 100} 
                        onValueChange={(e) => setVariant({ ...productVariant, tax: e / 100 })}
                        className="border border-gray-400 px-2 py-1 rounded w-full" />
                    </div>
                    <div className="w-full ml-4">
                    <Subtitle><b>Envio</b> <i>(Costo Envio)</i></Subtitle>
                    <NumberInput 
                        icon={CurrencyDollarIcon} 
                        placeholder="$ 0.00" 
                        value={productVariant.shippingCost} 
                        onValueChange={(e) => setVariant({ ...productVariant, shippingCost: e })}
                        className="border border-gray-400 px-2 py-1 rounded w-full" />
                    </div>
                </Flex>

                <Flex className="my-4">
                    <div className="w-80">
                    <Subtitle>Porcentaje de ganancia</Subtitle>
                    <Metric> 
                        { ((productVariant.salePrice - productVariant.price) / productVariant.price * 100).toFixed(2) }% 
                    </Metric>
                    </div>
                    <div>
                    <Subtitle>Ganancia Neta</Subtitle>
                    <Metric>
                        { dataFormatter(productVariant.salePrice - productVariant.price - (productVariant.salePrice * productVariant.tax) - (productVariant.salePrice * paymentFee) - fixedPaymentCost - productVariant.shippingCost) } 
                    </Metric>
                    </div>
                </Flex>
                <Grid numItems={1} numItemsSm={2} className="gap-8">
                    <Card>
                        <Metric>Imagenes</Metric>
                        <Subtitle className="mt-1">Las imagenes son importantes para que los clientes puedan ver el producto, recuerda elegir imagenes de buena calidad, buena iluminacion y que muestren el producto de la mejor manera posible. La primera imagen de la lista sera la imagen principal del producto.</Subtitle>
                        <Title className="mt-4">Las imagenes deben ser de formato JPG, JPEG o PNG.</Title>
                        <input onChange={(e) => imageHandler(e)} accept=".gif,.jpg,.jpeg,.png" type="file" className="border border-gray-400 px-2 py-1 rounded w-full bg-slate-300" multiple />
                    </Card>

                    <List className="w-full">
                    <ListItem>
                        <span>Ganancia</span>
                        <span>{ dataFormatter(productVariant.salePrice - productVariant.price - productVariant.shippingCost) } </span>
                    </ListItem>
                    <ListItem>
                        <span>Costo de pasarela pagos</span>
                        <span>{ dataFormatter((productVariant.salePrice * paymentFee) + fixedPaymentCost) }  </span>
                    </ListItem>
                    <ListItem>
                        <span>Costo de envio</span>
                        <span>{ dataFormatter(productVariant.shippingCost) } </span>
                    </ListItem>
                    <ListItem>
                        <span>Impuesto</span>
                        <span>{ dataFormatter(productVariant.salePrice * productVariant.tax) } </span>
                    </ListItem>
                    <ListItem>
                        <span>Ganancia Neta</span>
                        <span>{ dataFormatter(productVariant.salePrice - productVariant.price - (productVariant.salePrice * productVariant.tax) - ((productVariant.salePrice * paymentFee) + fixedPaymentCost)) } </span>
                    </ListItem>
                    <ListItem>
                        <span>Ganancia Bruta</span>
                        <span>{ dataFormatter(productVariant.salePrice - productVariant.price - ((productVariant.salePrice * paymentFee) + fixedPaymentCost)) }</span>
                    </ListItem>
                    </List>
                </Grid>
                </div>
            </div>
            </Card>

            <Card className="mt-4" decoration="bottom" decorationColor="blue">
                <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6">
                    {resources.map((image, index) => {
                        <>
                        <h1>A</h1>
                        { console.log("PPPP" + image) }
                        <div key={index} className="relative w-48">
                            <div className="absolute right-0 bottom-0 w-full z-10 bg-slate-300 rounded opacity-30 hover:opacity-100">
                                <Icon icon={TrashIcon} className="w-6 h-6 cursor-pointer" onClick={() => { }} />
                            </div>
                            <div className="relative z-0">
                                <p>{ image }</p>
                                <img src={ 'data:' + image.ext + ';base64,' + image.dat } alt={image.name} className="w-48 h-48 rounded" />
                            </div>
                        </div>
                        </>
                    })}
                </div>
            </Card>
        </>
    )
}

export default ProductVariantForm
