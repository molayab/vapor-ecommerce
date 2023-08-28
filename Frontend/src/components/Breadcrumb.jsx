import { Subtitle } from "@tremor/react";
import { useNavigate } from "react-router-dom";

function Breadcrumb({ pathArray }) {
  const navigate = useNavigate();

  return (
    <nav className="pt-3" aria-label="Breadcrumb">
      <ol className="inline-flex items-center space-x-1 md:space-x-3">
        {pathArray.map((path, index) => {
          if (index === 0) {
            return (
              <li key={index}>
                <div 
                  onClick={(e) => {
                    e.preventDefault();
                    navigate("/");
                  }}
                  className="flex items-center">
                  <Subtitle 
                    className="ml-1 text-sm font-medium hover:text-blue-600 md:ml-2 cursor-pointer">Home</Subtitle>
                </div>
              </li>
            )
          } else {
            return (
              <li key={index}>
                <div className="flex items-center">
                  <Subtitle>/</Subtitle>
                  <Subtitle onClick={(e) => {
                      e.preventDefault();
                      let path = pathArray.slice(0, index + 1).join("/");
                      navigate(path);
                    }}
                    className="ml-1 text-sm font-medium hover:text-blue-600 md:ml-2 capitalize cursor-pointer">{path}</Subtitle>
                </div>
              </li>
            )
          }
        })}
      </ol>
    </nav>
  );
}

export default Breadcrumb;