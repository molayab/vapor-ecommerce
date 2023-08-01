import { useEffect } from "react";
import Breadcrumb from "../../components/Breadcrumb";
import Header from "../../components/Header";
import SideMenu from "../../components/SideMenu";
import SubHeader from "../../components/SubHeader";
import { imagesToSendableResource } from "./CreateProduct";
import { API_URL } from "../../App";
import { useParams } from "react-router-dom";
import { useNavigate } from "react-router-dom";

function CreateProductVariant() {
  let { id } = useParams();
  const navigate = useNavigate();

  const onSubmit = async () => {
    const name = document.querySelector('input[name="variantName"]').value;
    const sku = document.querySelector('input[name="variantSku"]').value;
    const price = document.querySelector('input[name="variantPrice"]').value;
    const salePrice = document.querySelector('input[name="variantSalePrice"]').value;
    const stock = document.querySelector('input[name="variantStock"]').value;
    const available = document.querySelector('select[name="variantAvailable"]').value === 'true';
    const images = document.querySelector('input[name="variantFiles[]"]').files;
    
    let imageSrcs = await imagesToSendableResource([{images: images}])
    
    const variant = {
      name: name,
      sku: sku,
      price: parseFloat(price),
      salePrice: parseFloat(salePrice),
      stock: parseInt(stock),
      availability: available,
      images: imageSrcs
    };

    console.log(variant)

    const response = await fetch(API_URL + '/products/' + id + '/variants', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(variant)
    });

    const data = await response.json();
    if (data.id) {
      alert("Variant created");
      if (!confirm("Do you want to create another variant?")) {
        navigate(`/products/${id}`);
      }
    } else if (data.error) {
      alert(data.reason);
    }
  }

  return (
    <>
      <Header />
      <SideMenu>
        <SubHeader title="Create Product Variant">
          <button onClick={() => onSubmit() } className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
            Save
          </button>
        </SubHeader>

        <form className="w-full max-w-lg">
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

        </form>
      </SideMenu>
    </>
  )
}

export default CreateProductVariant;