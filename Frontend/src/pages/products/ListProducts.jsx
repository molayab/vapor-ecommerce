
import SideMenu from "../../components/SideMenu"
import ContainerCard from "../../components/ContainerCard"
import ProductGridCard from "./_components/ProductGridCard"
import Loader from "../../components/Loader"
import { Flex, TextInput } from "@tremor/react"
import { Button } from "@tremor/react"
import { useProducts } from "../../hooks/products"
import { useNavigate } from "react-router-dom"
import { currencyFormatter } from "../../helpers/dateFormatter"
import { useEffect, useState } from "react"
import { fetchProducts } from "../../components/services/products"
import { SearchIcon } from "@heroicons/react/solid"

function ListProducts() {
    const [page, setPage] = useState(1)
    const [query, setQuery] = useState(null)
    const navigate = useNavigate()
    const [localProducts, setLocalProducts] = useState(null)
    const [meta, setMeta] = useState({})

    const nextPage = () => {
        setPage((page) => page + 1)
    }

    const prevPage = () => {
        setPage((page) => page - 1)
    }

    useEffect(() => {
        const fetch = async () => {
            let response = await fetchProducts(page, query)
            let data = await response.json()
            setMeta({
                total: data.total,
                per: data.per,
                page: data.page,
            })

            setLocalProducts(data.items.map((i) => ({
                id: i.id,
                title: i.title,
                stars: i.numberOfStars,
                subtitle: `Variantes (${i.variants.length})`,
                stock: i.stock,
                minimumSalePrice: currencyFormatter(i.minimumSalePrice),
                averageSalePrice: currencyFormatter(i.averageSalePrice),
                variants: i.variants || [],
                isAvailable: i.variants.reduce((acc, v) => acc || v.isAvailable, false)
            })))
        }

        fetch()
    }, [page, query])

    if (localProducts === null) {
        return (<Loader />)
    }

    return (
        <SideMenu>
            <ContainerCard title="Productos" subtitle="Administrador de" action={
                <Button onClick={() => navigate("/products/new")}>Nuevo Producto</Button>
            }>

                <TextInput
                    onKeyDown={(e) => {
                        if (e.key !== "Enter") {
                            return
                        }
                        if (e.target.value === "") {
                            setQuery(null)
                            return
                        }
                        setQuery(e.target.value)
                    }}
                    icon={SearchIcon} className='w-full hover:bg-dark-tremor-background-emphasis bg-dark-tremor-background-emphasis' placeholder='Search...' />
            </ContainerCard>

            <ProductGridCard setProducts={setLocalProducts} products={localProducts} />
            <Flex justifyContent="end" className="space-x-2 pt-4 mt-8">
                <Button size="xs" variant="secondary" onClick={prevPage} disabled={page === 1}>
                Anterior
                </Button>

                <TextInput size="xs" className='w-10' value={page} readOnly />

                <Button size="xs" variant="primary" onClick={nextPage} disabled={page === (meta.total / meta.per).toFixed()}>
                Siguiente
                </Button>
            </Flex>
        </SideMenu>
    )
}

export default ListProducts