
import { API_URL } from '../App';
import { useState, useEffect } from 'react';

function CategorySelector({ name, callback }) {
  let isFetched = false;

  const [categories, setCategories] = useState([]);
  const fetchCategories = async () => {
    const response = await fetch(API_URL + '/categories', {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const data = await response.json();
    setCategories(data);
    isFetched = true;
  }

  const refreshCategories = async () => {
    isFetched = false;
    await fetchCategories();
  }

  useEffect(() => {
    fetchCategories();
  }, [isFetched]);

  callback(isFetched, refreshCategories)

  return (
    <select name={name} className="border border-gray-400 px-2 py-1 rounded w-full">
      {categories.map((category) => {
        return (
          <option key={category.id} value={category.id}>{category.title}</option>
        )
      })}
    </select>
  )
}

export default CategorySelector;