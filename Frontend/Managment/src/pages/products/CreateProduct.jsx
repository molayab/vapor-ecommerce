import Header from "../../components/Header";
import SideMenu from "../../components/SideMenu";
import SubHeader from "../../components/SubHeader";
import ImagePreview from "../../components/ImagePreview";
import CategorySelector from "../../components/CategorySelector";
import { useNavigate } from "react-router-dom";
import { useState } from "react";
import { API_URL } from "../../App";

function CreateProduct() {
  const [variants, setVariants] = useState([]);
  const navigate = useNavigate();
  let refreshCategories = null;

  function toBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        let encoded = reader.result.toString().replace(/^data:(.*,)?/, '');
        if ((encoded.length % 4) > 0) {
          encoded += '='.repeat(4 - (encoded.length % 4));
        }
        resolve(encoded);
      };
      reader.onerror = error => reject(error);
    });
  }

  const createVariant = (e) => {
    e.preventDefault();

    const name = document.querySelector('input[name="variantName"]').value;
    const sku = document.querySelector('input[name="variantSku"]').value;
    const price = document.querySelector('input[name="variantPrice"]').value;
    const salePrice = document.querySelector('input[name="variantSalePrice"]').value;
    const stock = document.querySelector('input[name="variantStock"]').value;
    const available = document.querySelector('select[name="variantAvailable"]').value === 'true';
    const images = document.querySelector('input[name="variantFiles[]"]').files;

    const variant = {
      name: name,
      sku: sku,
      price: parseFloat(price),
      salePrice: parseFloat(salePrice),
      stock: parseInt(stock),
      availability: available,
      images: images
    };

    setVariants([...variants, variant]);
  }

  const createCategory = async (e) => {
    e.preventDefault();

    let name = prompt("Category name");
    if (name === null || name === "") {
      alert("Category name is required");
      return;
    }

    const response = await fetch(API_URL + '/categories', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ title: name })
    });

    const data = await response.json();
    if (data.id) {
      if (refreshCategories) {
        refreshCategories();
        alert("Category created");
      }
    } else if (data.error) {
      alert(data.reason);
    }
  }

  const categoryBuilder = (isFetched, e) => {
    if (isFetched === false && e !== undefined) {
      refreshCategories = e;
    }
  }

  const publishProduct = async (e) => {
    e.preventDefault();

    if (variants.length === 0) {
      alert("You need to add at least one variant");
      return;
    }

    const name = document.querySelector('input[name="productName"]').value;
    const description = document.querySelector('input[name="productDescription"]').value;
    const categoryId = document.querySelector('select[name="category_selector"]').value;

    let images = []
    for (let i = 0; i < variants.length; i++) {
      for (let j = 0; j < variants[i].images.length; j++) {
        const image = variants[i].images[j]
        images.push(
          {
            dat: await toBase64(image),
            ext: image.name.split('.').pop()
          }
        )
      }
    }

    const playload = {
      title: name,
      description: description,
      category: categoryId,
      variants: variants.map((variant) => {
        return {
          name: variant.name,
          sku: variant.sku,
          price: variant.price,
          salePrice: variant.salePrice,
          stock: variant.stock,
          availability: variant.availability,
          images: images
        }
      })
    }

    console.log(playload);

    const response = await fetch(API_URL + '/products', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(playload)
    });

    const data = await response.json();
    if (data.id) {
      alert("Product created");
      navigate("/products");
    } else if (data.error) {
      alert(data.reason);
    }
  }

  return (
    <>
      <Header />
      <SideMenu>
        <form onSubmit={publishProduct}>
          <SubHeader title="Agregar Producto">
            <button 
              type="submit"
              className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
              Publish
            </button>  
          </SubHeader>

          <article className="border border-gray-400 px-2 py-2">


          <input type="text" name="productName" placeholder="Product name" className="border border-gray-400 px-2 py-1 rounded w-full" />
          <input type="text" name="productDescription" placeholder="Product description" className="border border-gray-400 px-2 py-1 rounded w-full" />
          <CategorySelector callback={categoryBuilder} name="category_selector" />
          <button
            onClick={ (e) => createCategory(e) }
            className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
            Add category
          </button>

          <h1>Variants</h1>
          <p>Variats are the different versions of your product. For example, if you sell t-shirts, you might have a variant for size and color.</p>

          <input type="text" name="variantName" placeholder="Variant name" className="border border-gray-400 px-2 py-1 rounded w-full" />
          <input type="text" name="variantSku" placeholder="Variant sku" className="border border-gray-400 px-2 py-1 rounded w-full" />
          <input type="text" name="variantPrice" placeholder="Variant price" className="border border-gray-400 px-2 py-1 rounded w-full" />
          <input type="text" name="variantSalePrice" placeholder="Variant sale price" className="border border-gray-400 px-2 py-1 rounded w-full" />
          <input type="text" name="variantStock" placeholder="Variant stock" className="border border-gray-400 px-2 py-1 rounded w-full" />
          <select name="variantAvailable" className="border border-gray-400 px-2 py-1 rounded w-full">
            <option>Variant available</option>
            <option value="true">Yes</option>
            <option value="false">No</option>
          </select>

          <h2>Variant images</h2>
          <p>Upload images for this variant</p>
          <input name="variantFiles[]" accept="image/*" type="file" className="border border-gray-400 px-2 py-1 rounded w-full" multiple />

          <button 
            onClick={ (e) => createVariant(e) }
            className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
            Add variant
          </button>


        </article>
        </form>

        <hr />
        <h1>Variants</h1>
        <div className="grid grid-cols-4 gap-4">
          {variants.map((variant) => {
            return (
              <div key={variant.id} className="border border-gray-400 p-2">
                <ImagePreview key={variant.id} image={variant.images[0]} />
                <p key={variant.id}>{variant.name}</p>
                <p key={variant.id}>{variant.sku}</p>
                <p key={variant.id}>{variant.price}</p>
                <p key={variant.id}>{variant.salePrice}</p>
                <p key={variant.id}>{variant.stock}</p>
                <p key={variant.id}>{variant.available ? "Available" : "Not available"}</p>
                <p key={variant.id}>{variant.images.length} images</p>
              </div>
            );
          })}
        </div>
      </SideMenu>
    </>
  );
}

export default CreateProduct;