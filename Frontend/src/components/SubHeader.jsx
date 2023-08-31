import { Card } from "@tremor/react";
import Breadcrumb from "./Breadcrumb";
import { useLocation } from "react-router-dom";

function SubHeader({ children, title }) {
  const router = useLocation();
  const parts = router.pathname.split("/");

  return (
    <div className="hidden sm:block">
      <Breadcrumb pathArray={parts} />
    </div>
  );
}

export default SubHeader;