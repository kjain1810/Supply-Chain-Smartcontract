import { useState, useContext, useEffect } from "react";
import { UserContext } from "../App";

export default function RegManufacturer() {
  const { blockchain } = useContext(UserContext);

  useEffect(() => {
    const init = async () => {
      updateSuppliers();
      // let temp = await blockchain.contract.methods.getAllSuppliers().call();
      // let temp = updateSuppliers();
      // setAllSuppliers(temp);
      // console.log(temp);
    };
    const updateSuppliers = async () => {
      let size = await blockchain.contract.methods.numSuppliers().call();
      let ret = [];
      console.log(size);
      for (let i = 1; i <= size; i++) {
        let temp = await blockchain.contract.methods.getSupplierByID(i).call();
        ret.push({
          tag: temp[0],
          partType: temp[1],
          quantityAvailable: temp[2],
          wallet: temp[3],
        });
      }
      setAllSuppliers(ret);
      console.log(ret);
    };
    init();
  }, [blockchain]);

  const [bodySup, setBodySup] = useState(0);
  const [wheelSup, setWheelSup] = useState(0);
  const [askPrice, setAskPrice] = useState(0);
  const [allSuppliers, setAllSuppliers] = useState([]);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        flex: "1",
      }}
    >
      <h1>Manufacturer Registration</h1>
      <div style={{ display: "flex", height: "100%" }}>
        <form
          style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-around",
            alignItems: "center",
            height: "100%",
            width: "40%",
          }}
        >
          <label>
            Body Supplier:
            <input
              type="number"
              value={bodySup}
              onChange={(e) => setBodySup(e.target.value)}
            />
          </label>
          <label>
            Wheel Supplier:
            <input
              type="number"
              value={wheelSup}
              onChange={(e) => setWheelSup(e.target.value)}
            />
          </label>
          <label>
            Set Cars Price:
            <input
              type="number"
              value={askPrice}
              onChange={(e) => setAskPrice(e.target.value)}
            />
          </label>
          <button
            type="button"
            onClick={async () => {
              try {
                await blockchain.contract.methods
                  .addManufacturer(
                    blockchain.userAccount,
                    wheelSup,
                    bodySup,
                    askPrice
                  )
                  .send({ from: blockchain.userAccount });
                window.location.assign("/homeManf");
              } catch (error) {
                alert("Something went wrong!");
              }
            }}
          >
            Submit
          </button>
        </form>
        <table>
          <thead>
            <tr>
              <th>tag</th>
              <th>partType</th>
              <th>quantity</th>
              <th>address</th>
            </tr>
          </thead>
          <tbody>
            {allSuppliers.map((supplier) => (
              <tr key={supplier.tag}>
                <td>{supplier.tag}</td>
                <td> {supplier.partType === "1" ? "Body" : "Wheel"}</td>
                <td>{supplier.quantityAvailable}</td>
                <td> {supplier.wallet}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
