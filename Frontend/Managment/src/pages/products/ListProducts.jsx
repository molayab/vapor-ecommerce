import { API_URL } from "../../App";
import Header from "../../components/Header";
import SideMenu from "../../components/SideMenu";
import SubHeader from "../../components/SubHeader";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useNavigate } from "react-router-dom";

function ListProducts() {
  const [products, setProducts] = useState([]);
  const navigate = useNavigate();
  let selectedProducts = [];

  useEffect(() => {
    const fetchProducts = async () => {
      const response = await fetch(API_URL + '/products', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      setProducts(data.items);

      console.log(data.items);
    };

    fetchProducts();
  }, []);

  const averagePrice = (prices) => {
    let total = 0;
    prices.forEach((price) => {
      total += price;
    });

    return total / prices.length;
  }

  const checkAvailability = (variants) => {
    return variants.map((e) => e.isAvailable).includes(true);
  }

  const deleteProduct = async (id) => {
    if (confirm("Are you sure you want to delete this product?") === false) {
      return;
    }

    const response = await fetch(API_URL + '/products/' + id, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    if (response.ok) {
      const newProducts = products.filter((product) => product.id !== id);
      setProducts(newProducts);
    }
  }

  const selectProduct = (e, id) => {
    if (e.target.checked && !selectedProducts.includes(id)) {
      selectedProducts.push(id);
    } else if (!e.target.checked) {
      selectedProducts = selectedProducts.filter((product) => product !== id);
    }
  }

  const selectAllProducts = (e) => {
    if (e.target.checked) {
      selectedProducts = products.map((product) => product.id);
    } else {
      selectedProducts = [];
    }

    // Mark all checks as checked
    const checkboxes = document.querySelectorAll('input[name="product"]');
    checkboxes.forEach((checkbox) => {
      checkbox.checked = e.target.checked;
    });
  }

  const deleteSelectedProducts = async () => {
    if (confirm("Are you sure you want to delete these products?") === false) {
      return;
    }

    for (let i = 0; i < selectedProducts.length; i++) {
      const response = await fetch(API_URL + '/products/' + selectedProducts[i], {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const newProducts = products.filter((product) => product.id !== selectedProducts[i]);
        setProducts(newProducts);
      }
    }
  }

  const navigateToDetails = (id) => {
    navigate("/products/" + id);
  }

  console.log(products);

  return (
    <>
      <Header />
      <SideMenu>
        <SubHeader title="Products">
          <button 
            onClick={() => deleteSelectedProducts()}
            className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded">
            Delete
          </button>
          <button 
            onClick={() => navigate("/products/create") }
            className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
            Add Product
          </button>
        </SubHeader>

        <table className="table-auto border-separate border border-slate-500 w-full">
          <thead>
            <tr>
              <th><input type="checkbox" onChange={(e) => selectAllProducts(e)} /></th>
              <th>Product</th>
              <th>Prices</th>
              <th>Disponibilidad</th>
              <th>Stock</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {products.map((product) => {
              return (<tr key={product.id} 
                className="self-center hover:bg-slate-200 cursor-pointer">
                <td>
                  <input onChange={(e) => selectProduct(e, product.id)} type="checkbox" name="product" />
                </td>
                <td onClick={() => navigateToDetails(product.id)}>
                  <div className="flex flex-row gap-2">
                    <img 
                      src={`http://localhost:8080/${product.variants[0].images[0]}`} 
                      alt={product.title} 
                      className="w-28 h-28 rounded" />
                    <div className="flex flex-col">

                      <p className="text-2xl">{product.title}</p>
                      <p className="text-xs">{product.id}</p>

                      <p className="text-xs">Prices</p>
                      <div className="flex flex-row gap-2">
                        <p className="text-xs">MIN $: {product.minimumSalePrice}</p>
                        <p className="text-xs">MAX $: {product.maximumSalePrice}</p>
                      </div>
                      <p className="text-xs">Variants: {product.variants.length}</p>
                    </div>
                  </div>
                </td>
                <td className="text-center"> $ {product.averageSalePrice}</td>
                <td className="text-center">
                  <input 
                    type="checkbox"
                    id="hs-basic-usage"
                    onChange={() => {}}
                    checked={checkAvailability(product.variants)}
                    className="relative w-[3.25rem] h-7 bg-gray-100 checked:bg-none checked:bg-blue-600 rounded-full cursor-pointer transition-colors ease-in-out duration-200 border border-transparent ring-1 ring-transparent focus:border-blue-600 focus:ring-blue-600 ring-offset-white focus:outline-none appearance-none dark:bg-gray-700 dark:checked:bg-blue-600 dark:focus:ring-offset-gray-800 before:inline-block before:w-6 before:h-6 before:bg-white checked:before:bg-blue-200 before:translate-x-0 checked:before:translate-x-full before:shadow before:rounded-full before:transform before:ring-0 before:transition before:ease-in-out before:duration-200 dark:before:bg-gray-400 dark:checked:before:bg-blue-200" />

                </td>
                <td className="text-center"> {product.stock}</td>
                <td className="flex flex-col cursor-pointer items-center">
                  <p className="text-blue-400 hover:text-blue-600">Edit</p>
                  <Link 
                    className="text-red-400 hover:text-red-600"
                    onClick={() => deleteProduct(product.id)}>Delete</Link>
                </td>
              </tr>);
            })}
          </tbody>
        </table>
      </SideMenu>
    </>
  );
}

export default ListProducts;