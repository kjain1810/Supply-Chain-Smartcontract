import { useContext } from "react";
import { UserContext } from "../App";

export default function Supplier() {
  const { isSupplier } = useContext(UserContext);
  return (
    <div>
      <h1>Welcome Supplier!</h1>
      <h1>{isSupplier ? "true" : "false"}</h1>
    </div>
  );
}
