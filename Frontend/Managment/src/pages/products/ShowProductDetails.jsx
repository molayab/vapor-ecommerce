
import { useParams } from "react-router-dom";
import Header from "../../components/Header";
import SideMenu from "../../components/SideMenu";
import SubHeader from "../../components/SubHeader";
import { useEffect } from "react";
import { API_URL } from "../../App";
import { useState } from "react";

function ShowProductDetails() {
  let { id } = useParams();
  let [product, setProduct] = useState({
    variants: []
  });
  let isFetched = false;

  const fetchProduct = async () => {
    const response = await fetch(API_URL + '/products/' + id, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const data = await response.json();

    isFetched = true;
    setProduct(data);
  }

  useEffect(() => {
    fetchProduct();
  }, [isFetched]);

  return (
    <>
      <Header />
      <SideMenu>

      <SubHeader title={`${id}`}>
        <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Add Variant
        </button>
        <button className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
          Edit
        </button>
        <button className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded">
          Delete
        </button>
      </SubHeader>

      <main className= 'w-full px-2 py-2'>
        <nav className='flex flex-col gap-2'>
          <article className=''>
            <h2 className='text-xl font-bold'>Product</h2>
            <ul className='flex flex-col gap-2'>
              <li className='flex flex-row gap-2'>
                <span className='w-1/2'>Name</span>
                <span className='w-1/2'>{product.title}</span>
              </li>
              <li className='flex flex-row gap-2'>
                <span className='w-1/2'>Description</span>
                <span className='w-1/2'>0</span>
              </li>
              <li className='flex flex-row gap-2'>
                <span className='w-1/2'>Category</span>
                <span className='w-1/2'>0</span>
              </li>
              <li className='flex flex-row gap-2'>
                <span className='w-1/2'>Variants</span>
                <span className='w-1/2'>0</span>
              </li>
              </ul>
          </article>
        </nav>

        <nav className='flex flex-col gap-2'>
          <article className=''>
            <h2 className='text-xl font-bold'>Variants</h2>
          </article>
        </nav>

        {product.variants.map((variant) => {
          return (
            <article className='grid grid-cols-4 gap-2'>
              {variant.images.map((image) => {
                return (
                  <img 
                    src={`http://localhost:8080/${image}`} 
                    alt={product.title} 
                    className="w-28 h-28 rounded" />
                )
              })}
            </article>
          )
        })}
        
      </main>
      </SideMenu>
    </>
    
  )
}
export default ShowProductDetails