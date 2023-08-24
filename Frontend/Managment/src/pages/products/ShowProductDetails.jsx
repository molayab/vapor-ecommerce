
import Header from "../../components/Header"
import SideMenu from "../../components/SideMenu"
import SubHeader from "../../components/SubHeader"
import RateStarList from "../../components/RateStarList"
import { useProduct } from "../../hooks/products"
import { useDeleteVariant } from "../../hooks/variants"
import { useParams, useNavigate } from "react-router-dom"

function ShowProductDetails() {
    let { id } = useParams()
    let navigate = useNavigate()
    let product = useProduct(id)
    
    const deleteProductVariant = async (productId, variantId) => {
        if (confirm("Are you sure you want to delete this variant?") === false) {
            return
        }
        if (useDeleteVariant(productId, variantId) === true) {
            return navigate('/products')
        }
    }
    
    if (product === null) {
        return (<Loader />)
    }
    
    return (
        <>
            <Header />
            <SideMenu>
                <SubHeader title="">
                    <button 
                        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
                        onClick={ (e) => {
                            e.preventDefault();
                            navigate(`/products/${id}/variants`)
                        }}>
                        Add Variant
                    </button>
                    <button className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                        Edit
                    </button>
                    <button className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded">
                        Delete
                    </button>
                </SubHeader>
                
                <section className='flex flex-row gap-2 items-center px-2 pt-2'>
                    <img src={`http://localhost:8080/${product.variants[0].images[0]}`} 
                        alt={product.title} 
                        className="w-48 h-48 rounded" />
                    
                    <div className='flex flex-col gap-2'>
                        <h1 className='text-4xl font-bold'>{product.title}</h1>
                        <p className='text-xl'>{product.description}</p>
                        <RateStarList rate={product.numberOfStars} />
                        
                        <div className='flex flex-col gap-2'>
                            <span className='text-md'>${product.variants[0].price}</span>
                            <span className='text-md'>Stock: {product.variants[0].stock}</span>
                        </div>
                    
                        <span className='text-sm'>Categoria #{product.category.title}</span>
                    </div>
                </section>
                
                <section>
                    <h2 className='text-xl font-bold'>Variants</h2>
                    <table className="table-auto border-separate border border-slate-500 w-full">
                        <thead>
                            <tr>
                                <th>Variant</th>
                                <th>Price</th>
                                <th>Stock</th>
                                <th>Sale Price</th>
                                <th>Available</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {product.variants.map((variant) => {
                            return (
                            <tr key={variant.id}>
                                <td>{variant.name}</td>
                                <td>{variant.price}</td>
                                <td>{variant.stock}</td>
                                <td>{variant.salePrice}</td>
                                <td>{variant.available}</td>
                                <td>
                                    <button className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                                        Edit
                                    </button>
                                    <button 
                                        onClick={() => deleteProductVariant(product.id, variant.id)}
                                        className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded">
                                        Delete
                                    </button>
                                </td>
                            </tr>)})}
                        </tbody>
                    </table>
                </section>
                
                <section className="grid grid-cols-2">
                    <h2 className='text-xl font-bold'>Comments</h2>
                    <h2 className='text-xl font-bold'>Questions</h2>
                </section>
            </SideMenu>
        </>         
    )
}

export default ShowProductDetails