
import SideMenu from "../../components/SideMenu";
import ContainerCard from "../../components/ContainerCard"
import ProductGridCard from "../../components/ProductGridCard"
import Loader from "../../components/Loader";
import { Button } from "@tremor/react";
import { useProducts } from "../../hooks/products"
import { useNavigate } from "react-router-dom";

function ListProducts() {
    const products = useProducts()
    const navigate = useNavigate()
    const valueFormatter = (number) => `$ ${Intl.NumberFormat("us").format(number).toString()}`;

    // Loading state
    if (products === null) {
        return (<Loader />)
    }

    // Default state
    return (
        <>
        <SideMenu>
            <ContainerCard title="Productos" subtitle="Administrador de" action={
                <Button onClick={() => navigate("/products/new")}>Nuevo Producto</Button>
            }>
            </ContainerCard>

            <ProductGridCard products={products.items.map((i) => ({
            id: i.id,
            title: i.title,
            stars: i.numberOfStars,
            subtitle: `Variantes (${i.variants.length})`,
            stock: i.stock,
            minimumSalePrice: valueFormatter(i.minimumSalePrice),
            averageSalePrice: valueFormatter(i.averageSalePrice),
            coverImage: i.coverImage,
            isAvailable: i.variants.reduce((acc, v) => acc || v.isAvailable, false),
            }))} />

        </SideMenu>
        </>
    )
}

export default ListProducts