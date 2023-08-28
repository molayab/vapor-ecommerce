import { Card } from "@tremor/react";
import Breadcrumb from "./Breadcrumb";
import { useLocation } from "react-router-dom";

function SubHeader({ children, title }) {
  const router = useLocation();
  const parts = router.pathname.split("/");

  return (
    <>
      <Breadcrumb pathArray={parts} />
    </>
  );
}

export default SubHeader;