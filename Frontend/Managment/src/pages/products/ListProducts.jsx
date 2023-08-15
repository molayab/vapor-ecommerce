import { API_URL } from "../../App";
import Header from "../../components/Header";
import SideMenu from "../../components/SideMenu";
import SubHeader from "../../components/SubHeader";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useNavigate } from "react-router-dom";
import { Button, Flex, Grid, Icon, Metric, NumberInput, Select, SelectItem, Subtitle, Title } from "@tremor/react";

import { Card } from "@tremor/react";
import ContainerCard from "../../components/ContainerCard";
import { PencilIcon, TrashIcon, ViewListIcon } from "@heroicons/react/outline";
import RateStarList from "../../components/RateStarList";
import ProductGridCard from "../../components/ProductGridCard";

function ListProducts() {
  const [products, setProducts] = useState({ items: [] });
  const navigate = useNavigate();
  const valueFormatter = (number) => `$ ${Intl.NumberFormat("us").format(number).toString()}`;
  
  const fetchProducts = async () => {
    const response = await fetch(`${API_URL}/products`, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      }
    });

    const data = await response.json();
    console.log(data);
    setProducts(data);
  }

  useEffect(() => {
    fetchProducts();
  }, []);

  return (
    <>
      <SideMenu>
        <ContainerCard title="Productos" subtitle="Administrador de" action={
            <Button onClick={() => navigate("/products/new")}>Nuevo Producto</Button>
          }>
        </ContainerCard>

        <Title className="mt-4">Todos los produtos</Title>
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
  );
}

export default ListProducts;