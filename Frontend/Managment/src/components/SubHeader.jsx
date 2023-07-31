import Breadcrumb from "./Breadcrumb";
import { useLocation } from "react-router-dom";

function SubHeader({ children, title }) {
  const router = useLocation();
  const parts = router.pathname.split("/");

  return (
    <>
      <nav className='flex flex-row w-full items-center px-2 bg-yellow-300'>
        <div className="flex-auto">
          <h1 className="text-4xl">{title}</h1>
          <Breadcrumb pathArray={parts} />
        </div>
        <div className="flex-grow"></div>
        <div className="flex-none h-full">
          <div className="flex flex-row-reverse items-center gap-2">
            {children}
          </div>
        </div>
      </nav>
    </>
  );
}

export default SubHeader;