
import { Select, SelectItem } from '@tremor/react';
import { API_URL } from '../App';
import { useState, useEffect } from 'react';

function CategorySelector({ name, callback, value, setValue }) {
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
    <Select name={name} className="w-full" value={value} onValueChange={setValue}>
      {categories.map((category) => {
        return (
          <SelectItem key={category.id} value={category.id}>{category.title}</SelectItem>
        )
      })}
    </Select>
  )
}

export default CategorySelector;