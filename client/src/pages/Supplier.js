import { useContext, useState, useEffect } from "react";
import { UserContext } from "../App";

export default function Supplier() {
  const { blockchain } = useContext(UserContext);
  const { isSupplier } = useContext(UserContext);
  const [auction_state, setAucState] = useState("loading...");
  const [ID, setID] = useState(0);
  const [bid_details, setBidDetails] = useState([]);

  const init = async () => {
    let temp = await blockchain.contract.methods
      .getSupplierID(blockchain.userAccount)
      .call();
    setID(temp);
    console.log(temp);

    console.log("ID:", temp);
    let temp1 = await blockchain.contract.methods.getAuctionState(temp).call();
    if (temp1 == 1) setAucState("NOT_RUNNING");
    else if (temp1 == 2) setAucState("BIDDING");
    else if (temp1 == 3) setAucState("REVEALING");
    console.log(temp1);
  };

  const getallbids = async () => {
    let temp = await blockchain.contract.methods
      .getSupplierBids(ID)
      .call();
    console.log(temp);
    setBidDetails(temp);
  }


  useEffect(() => {
    init();
  }, [blockchain]);

  return (
    <div>
      <h1>Welcome Supplier!</h1>
      <h1>{isSupplier ? "true" : "false"}</h1>
      <h1> Current State of Auction is {auction_state}</h1>
      <h2>
        {auction_state == "NOT_RUNNING" ? (
          <button
            type="button"
            onClick={async () => {
              try {
                await blockchain.contract.methods
                  .supplierStartBidding(ID)
                  .send({ from: blockchain.userAccount });
                init();
              } catch (error) {
                alert("Something went wrong!"); //has error here
              }
            }}
          >
            {" "}
            Start Auction
          </button>
        ) : (
          ""
        )}
      </h2>
      <h2>
        {auction_state == "BIDDING" ? (
          <button
            type="button"
            onClick={async () => {
              try {
                await blockchain.contract.methods
                  .supplierStartReveal(ID)
                  .send({ from: blockchain.userAccount });
                init();
              } catch (error) {
                alert("Something went wrong!"); //has error here
              }
            }}
          >
            Stop bids and start reveal phase
          </button>
        ) : (
          ""
        )}
      </h2>
      

      <h2>
        {auction_state == "REVEALING" ? (
          <button
            type="button"
            onClick={async () => {
              try {
                await blockchain.contract.methods
                  .supplierEndAuction(ID)
                  .send({ from: blockchain.userAccount });
                init();
              } catch (error) {
                alert(error);
              }
            }}
          >
            End Reveal Phase
          </button>
        ) : (
          ""
        )}
      </h2>
    </div>
  );
}
