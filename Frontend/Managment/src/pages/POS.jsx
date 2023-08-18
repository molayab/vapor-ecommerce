import React, { Component, useEffect, useState } from 'react'
import { QrReader } from 'react-qr-reader'
import SideMenu from '../components/SideMenu'
import { Card, Flex, Grid, Button, Title, Metric, Subtitle, List, ListItem, SearchSelect, SearchSelectItem, Icon, Table, TableHead, TableRow, TableHeaderCell, TableBody, TableCell, NumberInput } from '@tremor/react'
import ContainerCard from '../components/ContainerCard'
import { CashIcon, CreditCardIcon, CurrencyDollarIcon, MinusCircleIcon, SaveIcon, SearchIcon, TrashIcon } from '@heroicons/react/solid'
import { API_URL } from '../App'
import Checkout from './Checkout'

export default function POS() {
    function beep() {
        var snd = new Audio("data:audio/wav;base64,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qJrx4KOQjahZxWbcZgztj2c49nKmkId44S71j0c8eV9yDK6uPRzx5X18eDvjvQ6yKo9ZSS6l//8elePK/Lf//IInrOF/FvDoADYAGBMGb7FtErm5MXMlmPAJQVgWta7Zx2go+8xJ0UiCb8LHHdftWyLJE0QIAIsI+UbXu67dZMjmgDGCGl1H+vpF4NSDckSIkk7Vd+sxEhBQMRU8j/12UIRhzSaUdQ+rQU5kGeFxm+hb1oh6pWWmv3uvmReDl0UnvtapVaIzo1jZbf/pD6ElLqSX+rUmOQNpJFa/r+sa4e/pBlAABoAAAAA3CUgShLdGIxsY7AUABPRrgCABdDuQ5GC7DqPQCgbbJUAoRSUj+NIEig0YfyWUho1VBBBA//uQZB4ABZx5zfMakeAAAAmwAAAAF5F3P0w9GtAAACfAAAAAwLhMDmAYWMgVEG1U0FIGCBgXBXAtfMH10000EEEEEECUBYln03TTTdNBDZopopYvrTTdNa325mImNg3TTPV9q3pmY0xoO6bv3r00y+IDGid/9aaaZTGMuj9mpu9Mpio1dXrr5HERTZSmqU36A3CumzN/9Robv/Xx4v9ijkSRSNLQhAWumap82WRSBUqXStV/YcS+XVLnSS+WLDroqArFkMEsAS+eWmrUzrO0oEmE40RlMZ5+ODIkAyKAGUwZ3mVKmcamcJnMW26MRPgUw6j+LkhyHGVGYjSUUKNpuJUQoOIAyDvEyG8S5yfK6dhZc0Tx1KI/gviKL6qvvFs1+bWtaz58uUNnryq6kt5RzOCkPWlVqVX2a/EEBUdU1KrXLf40GoiiFXK///qpoiDXrOgqDR38JB0bw7SoL+ZB9o1RCkQjQ2CBYZKd/+VJxZRRZlqSkKiws0WFxUyCwsKiMy7hUVFhIaCrNQsKkTIsLivwKKigsj8XYlwt/WKi2N4d//uQRCSAAjURNIHpMZBGYiaQPSYyAAABLAAAAAAAACWAAAAApUF/Mg+0aohSIRobBAsMlO//Kk4soosy1JSFRYWaLC4qZBYWFRGZdwqKiwkNBVmoWFSJkWFxX4FFRQWR+LsS4W/rFRb/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////VEFHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAU291bmRib3kuZGUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMjAwNGh0dHA6Ly93d3cuc291bmRib3kuZGUAAAAAAAAAACU=");  
        snd.play();
    }

    let lastScanDate = Date.now()
    const shouldUseCache = () => {
        return !(localStorage.getItem('products') != "undefined" 
            || localStorage.getItem('products') != null 
            || localStorage.getItem('products') != "null" 
            || localStorage.getItem('products') != ""
            || localStorage.getItem('products') != "[]"
            || localStorage.getItem('products') != []
            || localStorage.getItem('products') != undefined)
    }

    const [pay, setPay] = useState(false)
    const [checkoutList, setCheckoutList] = useState([])
    const [variant, setVariant] = useState(null)
    const [products, _setProducts] = useState(shouldUseCache() ? JSON.parse(localStorage.getItem('products')) : [])
    const setProducts = (products) => {
        localStorage.setItem('products', JSON.stringify(products))
        _setProducts(products)
    }

    const getAllVariants = () => {
        if (!products) {
            return []
        }

        let variants = []
        products.forEach((product) => {
            product.variants.forEach((variant) => {
                variants.push({...variant, name: product.title + ' - ' + variant.name + ' - ' + variant.sku})
            })
        })

        return variants
    }

    const fetchAllProducts = async () => {
        let response = await fetch(API_URL + '/products/pos', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        })

        let data = await response.json()

        if (data.length) {
            return data
        } else if (data.error) {
            alert(data.reason)
            return []
        }
    }

    const addItemToCheckoutList = (variant) => {
        let list = [...checkoutList]
        let index = list.findIndex((item) => item.id === variant.id)

        console.log(variant)
        console.log(index)
        console.log(list)

        if (index === -1) {
            list.push({...variant, quantity: 1})
        } else {
            list[index].quantity += 1
        }

        beep()
        return list
    }

    const [qrCode, setQrCode] = useState(null)

    const onQrCodeRead = (result) => {
        let variant = getAllVariants().find((variant) => variant.sku === result)
        if (variant) {
            setCheckoutList(addItemToCheckoutList(variant))
        }

        setQrCode(null)
    }

    const deleteItemFromCheckoutList = (index) => {
        let list = [...checkoutList]
        list.splice(index, 1)
        setCheckoutList(list)
    }

    useEffect(() => {
        onQrCodeRead(qrCode)
    }, [qrCode])

    useEffect(() => {
        fetchAllProducts().then((data) => {
            setProducts(data)
        })
    }, [])

    if (pay && checkoutList.length > 0) {
        return (
            <Checkout checkoutList={checkoutList} />
        )
    }

    return (
        <>
        <SideMenu>
            <Flex className='gap-1'>
                <Card>  
                    <Flex>
                        <div className='w-full mr-4'>
                            <Title>Total</Title>
                            <Metric>$ { checkoutList.reduce((total, item) => total + (item.quantity * item.salePrice * (1 + item.tax)), 0) }</Metric>
                            <Subtitle>{ checkoutList.reduce((total, item) => total + item.quantity, 0) } productos</Subtitle>

                            <List>
                                <ListItem>
                                    <span>Subtotal</span>
                                    <span>$ { checkoutList.reduce((total, item) => total + (item.quantity * item.salePrice), 0) }</span>
                                </ListItem>
                                <ListItem>
                                    <span>Impuesto</span>
                                    <span>$ { checkoutList.reduce((total, item) => total + (item.quantity * item.salePrice * item.tax), 0) }</span>
                                </ListItem>
                            </List>
                            <Button onClick={ (e) => setPay(true) } disabled={checkoutList.length === 0 && !pay} color='green' size='xs' icon={CreditCardIcon} className='w-full mt-4'>Cobrar</Button>
                            <Button color='rose' size='xs' variant='secondary' icon={MinusCircleIcon} className='w-full mt-4'>Limpiar</Button>
                        </div>
                    
                        <Flex className='justify-center w-48'>
                            <div className="w-48 h-48 rounded">
                                <QrReader
                                    ViewFinder={ViewFinder}
                                    scanDelay={1500}
                                    onResult={(result) => {
                                        if (result) {
                                            if (lastScanDate + 1000 > Date.now()) {
                                                return
                                            }
                                            lastScanDate = Date.now()
                                            setQrCode(result.getText())
                                        }
                                    }} />
                            </div>
                        </Flex>
                    </Flex>
                </Card>
            </Flex>
            
            <Card decoration='bottom' className='mt-4' decorationColor='green'>
                <SearchSelect icon={SearchIcon} placeholder='Buscar producto' onValueChange={(value) => {
                        setCheckoutList(addItemToCheckoutList(getAllVariants().find((variant) => variant.id === value)))
                    }} 
                    value={variant}>
                    
                    {getAllVariants().map((variant) => {
                        return (
                            <SearchSelectItem key={variant.id} value={variant.id}>{variant.name}</SearchSelectItem>
                        )
                    })}
                </SearchSelect>

                <Title className='mt-4'>Factura</Title>
                <Subtitle>Productos a facturar</Subtitle>
                <Table>
                    <TableHead>
                        <TableRow>
                            <TableHeaderCell>Variante del producto</TableHeaderCell>
                            <TableHeaderCell>Cantidad</TableHeaderCell>
                            <TableHeaderCell>Costo Unitario</TableHeaderCell>
                            <TableHeaderCell>Costo Total</TableHeaderCell>
                            <TableHeaderCell>Acciones</TableHeaderCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {checkoutList.map((item) => {
                            return (
                                <TableRow key={item.id}>
                                    <TableCell>{ item.name }</TableCell>
                                    <TableCell>
                                        <NumberInput value={item.quantity} onValueChange={(value) => { 
                                            let list = [...checkoutList]
                                            let index = list.findIndex((i) => i.id === item.id)
                                            list[index].quantity = value
                                            setCheckoutList(list)
                                        }} />
                                    </TableCell>
                                    <TableCell>
                                        <NumberInput icon={CurrencyDollarIcon} enableStepper={false} value={item.salePrice} onValueChange={(value) => {
                                            let list = [...checkoutList]
                                            let index = list.findIndex((i) => i.id === item.id)
                                            list[index].salePrice = value
                                            setCheckoutList(list)
                                        }} />
                                    </TableCell>
                                    <TableCell><Title>{ item.salePrice * item.quantity }</Title></TableCell>
                                    <TableCell>
                                        <Icon icon={TrashIcon} className='cursor-pointer' onClick={() => { deleteItemFromCheckoutList(checkoutList.findIndex((i) => i.id === item.id)) }} />
                                    </TableCell>
                                </TableRow>
                            )
                        })}
                    </TableBody>
                </Table>
            </Card>

            <Card>

            </Card>
        </SideMenu>
        
        </>
    )
}

export const ViewFinder = () => (
    <>
      <svg
        width="50px"
        viewBox="0 0 100 100"
        style={{
          top: 0,
          left: 0,
          zIndex: 1,
          boxSizing: 'border-box',
          border: '10px solid rgba(0, 0, 0, 0.3)',
          position: 'absolute',
          width: '100%',
          height: '100%',
        }}
      >
        <path
          fill="none"
          d="M13,0 L0,0 L0,13"
          stroke="rgba(255, 0, 0, 0.5)"
          strokeWidth="5"
        />
        <path
          fill="none"
          d="M0,87 L0,100 L13,100"
          stroke="rgba(255, 0, 0, 0.5)"
          strokeWidth="5"
        />
        <path
          fill="none"
          d="M87,100 L100,100 L100,87"
          stroke="rgba(255, 0, 0, 0.5)"
          strokeWidth="5"
        />
        <path
          fill="none"
          d="M100,13 L100,0 87,0"
          stroke="rgba(255, 0, 0, 0.5)"
          strokeWidth="5"
        />
      </svg>
    </>
  );