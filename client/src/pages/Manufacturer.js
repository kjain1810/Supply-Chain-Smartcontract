import { useContext, useState, useEffect } from "react";
import { UserContext } from "../App";

export default function Manufacturer() {
  const { blockchain } = useContext(UserContext);
  
 
  return <h1>Welcome Manufacturer!</h1>;
}
