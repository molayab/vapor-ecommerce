import { Card, Flex, Grid, NumberInput, Select, SelectItem, Subtitle, Title } from "@tremor/react";
import { PencilIcon, TrashIcon } from "@heroicons/react/outline";
import RateStarList from "./RateStarList";
import { useNavigate } from "react-router-dom";

function ProductGridCard({ products }) {
    const navigate = useNavigate()

    return (
        <Grid numItems={1} numItemsSm={1} numItemsMd={1} numItemsLg={3} className="gap-4 mt-4">
            { products.map((product, index) => (
                    <Card 
                        onClick={() => navigate(`/products/${product.id}`)}
                        key={index} 
                        decorationColor={ product.isAvailable ? "green" : "rose" } 
                        decoration="bottom" 
                        className="hover:cursor-pointer hover:border-lime-100">
                        <div className="flex items-start gap-4">
                            <img src={product.coverImage} width={100} height={100} className="flex-none rounded aspect-square" />
                            <div className="flex-1">
                                <Title>{ product.title }</Title>
                                <Subtitle>{ product.minimumSalePrice }</Subtitle>
                                <Subtitle>{ product.subtitle }</Subtitle>
                                <RateStarList rate={product.stars} />
                            </div>
                            <div>
                                <Title className="text-right">
                                    { product.averageSalePrice }
                                </Title>
                                <Subtitle>
                                    precio promedio
                                </Subtitle>
                            </div> 
                        </div>

                        <Flex className="mt-4">
                            <div className="">
                                <Subtitle>Disponibles</Subtitle>
                                <NumberInput placeholder="Inventario" value={product.stock} aria-label="Inventario" readOnly disabled />
                            </div>
                            <div className="">
                                <Subtitle>Acciones</Subtitle>
                                <Select>
                                    <SelectItem value="1" icon={TrashIcon}>Eliminar</SelectItem>
                                    <SelectItem value="2" icon={PencilIcon}>Editar</SelectItem>
                                </Select>
                            </div>
                        </Flex>
                    </Card>
                )
            )}
        </Grid>
    )
}

export default ProductGridCard