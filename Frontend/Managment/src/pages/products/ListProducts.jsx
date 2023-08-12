import { API_URL } from "../../App";
import Header from "../../components/Header";
import SideMenu from "../../components/SideMenu";
import SubHeader from "../../components/SubHeader";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useNavigate } from "react-router-dom";

import { Card } from "@tremor/react";
import ContainerCard from "../../components/ContainerCard";

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
        <SideMenu>
          <ContainerCard>
            
          </ContainerCard>

        </SideMenu>
    </>
  );
}

export default ListProducts;