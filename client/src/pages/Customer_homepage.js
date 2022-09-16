import { useContext, useState, useEffect } from "react";
import { UserContext } from "../App";

export default function Customer_homepage() {
   const { blockchain } = useContext(UserContext);
   const [manf_addr, set_manf_addr] = useState("");
   const  [ID, setID] = useState(0);
   const [manf_ID, set_manf_ID] = useState(0);
   const [price_paying, set_price_paying] = useState(0);
   const [quant_needed, set_quant_needed] = useState(0);
   const [cars_available, set_cars_available] = useState(0);
   const [cars_price, set_cars_price] = useState(0);

   const get_manufacturer_details = async () => {
    try{
      let temp = await blockchain.contract.methods
         .getManufacturerID(manf_addr)
         .call();

      set_manf_ID(temp[0]);
      console.log("ID: ", temp);
      set_cars_available(temp[5]);
      set_cars_price(temp[6]);
    }catch(error)
    {
      console.log(error)
    }
   }
  return (
    <div>
      <h1>Welcome Customer!</h1>
      <h3>Get Manufacturer Details</h3>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-around",
          alignItems: "center",
          height: "20%",
          width: "40%",
        }}
      >
        <form>
          <label>
            Enter manufacturer Address: :
            <input
              type="string" //to be changed to address, nope works
              value={manf_addr}
              onChange={(e) => set_manf_addr(e.target.value)}
            />
          </label>
          <button
            type="button"
            onClick={async () => {
              get_manufacturer_details();
            }}
          >
            Get Details
          </button>
        </form>
      </div>
      <div>
        <table>
          <thead>Suppliers Details</thead>
          <thead>
            <tr>
              <th>Manufacturer ID</th>
              <th>Cars Available</th>
              <th>Cars Price</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{manf_ID}</td>
              <td>{cars_available}</td>
              <td> {cars_price}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div>
        <form
        style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-around",
            alignItems: "center",
            height: "100%",
            width: "40%",
          }}>
            <h4>Make a purchase </h4>
            <label>
                Enter Manufacturer ID:
                <input
                    type="number"
                    value={manf_ID}
                    onChange={(e) => set_manf_ID(e.target.value)}
                />
            </label>
            <label>
                Enter Quantity:
                <input
                    type="number"
                    value={quant_needed}
                    onChange={(e) => set_quant_needed(e.target.value)}
                />
            </label>
            <label>
                Enter Price:
                <input
                    type="number"
                    value={price_paying}
                    onChange={(e) => set_price_paying(e.target.value)}
                />
            </label>
            <button
                type="button"
                onClick={async () => {
                  try
                  {
                    await blockchain.contract.methods
                        .customerBuysCar(ID,manf_ID,price_paying,quant_needed)
                        .send({ from: blockchain.account });
                  }
                  catch(err)
                  {
                    console.log(err);
                    alert("Error in making purchase");
                  }
                }}
            >
                Make Purchase
            </button>
          </form>
      </div>
    </div>
  );

}
