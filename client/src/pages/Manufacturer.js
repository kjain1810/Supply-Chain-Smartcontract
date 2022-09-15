import { useContext, useState, useEffect } from "react";
import { UserContext } from "../App";

export default function Manufacturer() {
  const Web3 = require("web3");
  const { blockchain } = useContext(UserContext);
  const [wheel_sup, set_wheel_sup] = useState(0);
  const [body_sup, set_body_sup] = useState(0);
  const [ID, setID] = useState(0);
  const [wheel_sup_auction_state, setWAucState] = useState("loading...");
  const [body_sup_auction_state, setBAucState] = useState("loading...");
  const [wheel_quantity, setWheelQuantity] = useState(0); //should get it from new func?how much quantity does supplier have
  const [body_quantity, setBodyQuantity] = useState(0);
  const [bidto_supID, setSupID_toBid] = useState(0);
  const [quant_toBid, setquant_toBid] = useState(0);
  const [blindkey, setBlindkey] = useState(0);
  const [Bid, setBid] = useState(0);
  const [partType, setPartType] = useState("Wheels");
  const [cars_available, setCars] = useState(0);

  const init = async () => {
    let temp = [];
    temp = await blockchain.contract.methods
      .getManufacturerID(blockchain.userAccount)
      .call(); //gets all data
    console.log(temp);
    console.log(temp[0], temp[1], temp[3]);
    setID(temp[0]);
    set_wheel_sup(temp[1]);
    setWheelQuantity(temp[2]);
    set_body_sup(temp[3]);
    setBodyQuantity(temp[4]);
    setCars(temp[5]);
    console.log("wheel sup:", temp[1]);

    let temp1 = await blockchain.contract.methods
      .getAuctionState(temp[1])
      .call();

    if (temp1 == 1) setWAucState("NOT_RUNNING");
    else if (temp1 == 2) setWAucState("BIDDING");
    else if (temp1 == 3) setWAucState("REVEALING");
    console.log("wheel sup auction state:", wheel_sup_auction_state);
    console.log("body sup:", temp[3]);

    let temp2 = await blockchain.contract.methods
      .getAuctionState(temp[3])
      .call();
    if (temp2 == 1) setBAucState("NOT_RUNNING");
    else if (temp2 == 2) setBAucState("BIDDING");
    else if (temp2 == 3) setBAucState("REVEALING");
    console.log("body_sup_auction_state:", body_sup_auction_state);
  };

  const refresh = async () => {
    setBid(0);
    setBlindkey(0);
    setquant_toBid(0);
    setSupID_toBid(0);
    setPartType(0);
  };

  useEffect(() => {
    init();
  }, [blockchain]);

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        flex: "1",
      }}
    >
      <h1>Manufacturer Homepage</h1>
      <h2>Number of cars you have : {cars_available}</h2>
      <h3>Number of bodies you have :{body_quantity} </h3>
      <h3>Number of wheels you have :{wheel_quantity} </h3>
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
        <button
          type="button"
          onClick={async () => {
            alert("To be implemented");
          }}
        >
          View all customer requests
        </button>
      </div>
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
          <h4>Bidding Form</h4>
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
            Supplier ID:
            <input
              type="number"
              value={bidto_supID}
              onChange={(e) => setSupID_toBid(e.target.value)}
            />
          </label>
          <label>
            quantity:
            <input
              type="number"
              value={quant_toBid}
              onChange={(e) => setquant_toBid(e.target.value)}
            />
          </label>
          <label>
            Bid:
            <input
              type="number"
              value={Bid}
              onChange={(e) => setBid(e.target.value)}
            />
          </label>
          <label>
            Blind key:
            <input
              type="number"
              value={blindkey}
              onChange={(e) => setBlindkey(e.target.value)}
            />
          </label>
          <button
            type="button"
            onClick={async () => {
              if (partType == "Body" && body_sup_auction_state == "BIDDING") {
                if (quant_toBid > wheel_quantity) {
                  alert(
                    "You don't have enough wheel quantity, buy wheels first"
                  );
                } else {
                  try {
                    await blockchain.contract.methods
                      .manufacturerPlacesBid(
                        ID,
                        bidto_supID,
                        Web3.utils.soliditySha3(quant_toBid + blindkey),
                        Web3.utils.soliditySha3(Bid + blindkey),
                        Web3.utils.soliditySha3(blindkey)
                      )
                      .send({
                        value: Web3.utils.toWei(Bid, "ether"),
                        from: blockchain.userAccount,
                      });
                    alert("Bidding for bodies successful");
                  } catch (error) {
                    console.log(error);
                    alert("Error bidding");
                  }
                }
              } else if (
                partType == "Wheels" &&
                wheel_sup_auction_state == "BIDDING"
              ) {
                try {
                  await blockchain.contract.methods
                    .manufacturerPlacesBid(
                      ID,
                      bidto_supID,
                      Web3.utils.soliditySha3(quant_toBid + blindkey),
                      Web3.utils.soliditySha3(Bid + blindkey),
                      Web3.utils.soliditySha3(blindkey)
                    )
                    .send({
                      value: Bid,
                      from: blockchain.userAccount,
                    });
                  alert("Bidding for wheels successful");
                } catch (error) {
                  console.log(error);
                  alert("Error bidding");
                }
              } else {
                alert("Auction not running");
                refresh();
              }
            }}
          >
            Submit
          </button>
          <h4>Reveal Form</h4>
        </form>

        <table>
          <thead>Suppliers Details</thead>
          <thead>
            <tr>
              <th>Tag</th>
              <th>Part Type </th>
              <th>Auction_state</th>
              <th>
                <button
                  type="button"
                  onClick={async () => {
                    window.location.reload();
                  }}
                >
                  Refresh
                </button>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{wheel_sup}</td>
              <td>"Wheel"</td>
              <td> {wheel_sup_auction_state}</td>
            </tr>
            <tr>
              <td>{body_sup}</td>
              <td>"Body"</td>
              <td> {body_sup_auction_state}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
