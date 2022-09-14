import { Link, Outlet } from "react-router-dom";

export default function Assign() {
  return (
    <div style={{ display: "flex", flexDirection: "column", flex: "1" }}>
      <nav>
        <Link to="/assign/regSup">Supplier</Link>
        <Link to="/assign/regManf">Manufacturer</Link>
        <Link to="/assign/Cus_homepage">Customer</Link>
      </nav>
      <Outlet />
    </div>
  );
}
