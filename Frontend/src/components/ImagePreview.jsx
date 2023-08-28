import { useState } from 'react';

function ImagePreview({ children, image }) {
  const [result, setResult] = useState(<img src="" alt="preview" />);

  const reader = new FileReader();
  reader.onload = (e) => {
    setResult(<img src={e.target.result} alt="preview" />);
  }

  reader.readAsDataURL(image);

  return (
    <div className="image-preview">
      {result}
    </div>
  );
}

export default ImagePreview;