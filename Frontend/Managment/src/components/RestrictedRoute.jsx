import { useState, useEffect } from "react";
import { Route, Navigate } from "react-router-dom";

function RestrictedRoute({ children }) {
  if (localStorage.getItem("token")) {
    return children
  } else {
    return <Navigate to="/login" />
  }
}

export default RestrictedRoute;