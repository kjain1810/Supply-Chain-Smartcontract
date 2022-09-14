import { useState, useContext } from "react";
import { UserContext } from "../App";

export default function RegSupplier() {
  const [partType, setPartType] = useState("Body");
  const [quan, setQuant] = useState(0);
  const [bidderCount, setBidderCount] = useState(0);
  const { blockchain } = useContext(UserContext);
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        flex: "1",
      }}
    >
      <h1>Supplier Registration</h1>
      <form
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-around",
          alignItems: "center",
          flex: "100%",
        }}
      >
        <label>
          Part Type:
          <div>
            <input
              type="radio"
              value="Body"
              checked={partType === "Body"}
              onChange={(e) => setPartType(e.target.value)}
            />{" "}
            Body
            <input
              type="radio"
              value="Wheels"
              checked={partType === "Wheels"}
              onChange={(e) => setPartType(e.target.value)}
            />{" "}
            Wheels
          </div>
        </label>
        <label>
          Quantity:
          <input
            type="number"
            value={quan}
            onChange={(e) => setQuant(e.target.value)}
          />
        </label>
        <label>
          Bidder Count:
          <input
            type="number"
            value={bidderCount}
            onChange={(e) => setBidderCount(e.target.value)}
          />
        </label>
        <button
          type="button"
          onClick={async () => {
            try {
              await blockchain.contract.methods
                .addSupplier(
                  partType === "Body" ? 0 : 1,
                  quan,
                  blockchain.userAccount,
                  bidderCount
                )
                .send({ from: blockchain.userAccount });
              window.location.assign("/homeSup");
            } catch (error) {
              alert("Something went wrong!");
            }
          }}
        >
          Submit
        </button>
      </form>
    </div>
  );
}
