import React from "react";
import { Icon } from "@tremor/react";
import { TrashIcon } from "@heroicons/react/solid";
import { RES_URL } from "../../../App";
import { Table, TableBody, TableCell, TableHead, TableHeaderCell, TableRow, Title } from "@tremor/react";
import { currencyFormatter } from "../../../helpers/dateFormatter";

function VariantList({productCopy, navigate, id, deleteProductVariant}) {
    return <Table>
        <TableHead>
            <TableHeaderCell className="w-48"></TableHeaderCell>
            <TableHeaderCell>Variante</TableHeaderCell>
            <TableHeaderCell>Precio Venta / Costo</TableHeaderCell>
            <TableHeaderCell>Finanzas</TableHeaderCell>
            <TableHeaderCell></TableHeaderCell>
        </TableHead>
        <TableBody>
            {productCopy.variants !== undefined ? productCopy.variants.map((variant) => {
                return (
                    <TableRow className="hover:bg-slate-800 hover:cursor-pointer">
                        <TableCell onClick={(e) => { navigate("/products/" + id + "/variants/" + variant.id + "/edit") } }>
                            {variant.images.length > 0 && (
                                <img
                                    key={variant.id}
                                    src={RES_URL + variant.images[0]}
                                    className="relative z-10 rounded-xl w-32 h-32 shadow" />
                            )}
                        </TableCell>
                        <TableCell onClick={(e) => { navigate("/products/" + id + "/variants/" + variant.id + "/edit") } }>
                            <strong>{variant.name}</strong><br />
                            <small>{variant.sku}</small><br /><br />
                            <small>
                                <strong className={variant.isAvailable === true && variant.stock > 0 ? "text-green-500" : "text-rose-500"}>
                                    {variant.isAvailable === true && variant.stock > 0 ? "Disponible" : "No disponible"}
                                </strong>
                            </small><br />
                            <small>{variant.isAvailable === true && variant.stock > 0 ? variant.stock + " en stock" : "Sin stock"}</small>
                        </TableCell>
                        <TableCell onClick={(e) => { navigate("/products/" + id + "/variants/" + variant.id + "/edit") } }>
                            <strong>{currencyFormatter(variant.salePrice)}</strong><br />
                            <small>{currencyFormatter(variant.price)}</small><br />
                        </TableCell>
                        <TableCell onClick={(e) => { navigate("/products/" + id + "/variants/" + variant.id + "/edit") } }>
                            <strong>Iva:</strong><br />
                            <smail>{variant.tax}% - {currencyFormatter(variant.price * variant.tax)}</smail><br />
                            <strong>Ganancia:</strong><br />
                            <small className={variant.salePrice - variant.price - (variant.price * variant.tax) > 0 ? "text-green-500" : "text-rose-500"}>
                                {currencyFormatter(variant.salePrice - variant.price - (variant.price * variant.tax))}
                            </small><br />
                        </TableCell>
                        <TableCell className="w-32">
                            <Icon
                                onClick={(e) => { deleteProductVariant(variant) } }
                                icon={TrashIcon} />
                        </TableCell>
                    </TableRow>
                )
            }) : <Title>No hay variantes</Title>}
        </TableBody>
    </Table>
}

export default VariantList