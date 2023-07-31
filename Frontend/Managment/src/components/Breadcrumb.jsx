import { useNavigate } from "react-router-dom";

function Breadcrumb({ pathArray }) {
  const navigate = useNavigate();

  return (
    <nav className="flex px-5 py-3" aria-label="Breadcrumb">
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
                  <span 
                    className="ml-1 text-sm font-medium text-gray-700 hover:text-blue-600 md:ml-2">Home</span>
                </div>
              </li>
            )
          } else {
            return (
              <li key={index}>
                <div className="flex items-center">
                  <svg className="w-3 h-3 mx-1" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
                    <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="m1 9 4-4-4-4"/>
                  </svg>
                  <a href="#" 
                    onClick={(e) => {
                      e.preventDefault();
                      let path = pathArray.slice(0, index + 1).join("/");
                      navigate(path);
                    }}
                    className="ml-1 text-sm font-medium text-gray-700 hover:text-blue-600 md:ml-2">{path}</a>
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