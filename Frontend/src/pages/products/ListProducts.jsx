
import SideMenu from "../../components/SideMenu";
import ContainerCard from "../../components/ContainerCard"
import ProductGridCard from "./_components/ProductGridCard"
import Loader from "../../components/Loader";
import { Button } from "@tremor/react";
import { useProducts } from "../../hooks/products"
import { useNavigate } from "react-router-dom";
import { dataFormatter } from "../../helpers/dateFormatter";
import { useEffect, useState } from "react";

function ListProducts() {
    const products = useProducts()
    const navigate = useNavigate()
    const [localProducts, setLocalProducts] = useState(null)

    useEffect(() => {
        if (products) {
            setLocalProducts(products.items.map((i) => ({
                id: i.id,
                title: i.title,
                stars: i.numberOfStars,
                subtitle: `Variantes (${i.variants.length})`,
                stock: i.stock,
                minimumSalePrice: dataFormatter(i.minimumSalePrice),
                averageSalePrice: dataFormatter(i.averageSalePrice),
                variants: i.variants || [],
                isAvailable: i.variants.reduce((acc, v) => acc || v.isAvailable, false),
            })))
        }
    }, [products])

    if (products === null || localProducts === null) {
        return (<Loader />)
    }

    return (
        <SideMenu>
            <ContainerCard title="Productos" subtitle="Administrador de" action={
                <Button onClick={() => navigate("/products/new")}>Nuevo Producto</Button>
            }>
            </ContainerCard>

            <ProductGridCard setProducts={setLocalProducts} products={localProducts} />
        </SideMenu>
    )
}

export default ListProducts