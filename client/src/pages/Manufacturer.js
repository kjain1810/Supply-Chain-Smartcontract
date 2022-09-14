import { useContext, useState, useEffect } from "react";
import { UserContext } from "../App";

export default function Manufacturer() {
  const { blockchain } = useContext(UserContext);
  const [ wheel_sup, set_wheel_sup] = useState(0);
  const [ body_sup, set_body_sup] = useState(0);
  const [ID, setID] = useState(0);
  const [wheel_sup_auction_state, setWAucState] = useState("loading...");
  const [body_sup_auction_state, setBAucState] = useState("loading..."); 
  const [wheel_quantity, setWheelQuantity] = useState(0);  //should get it from new func?how much quantity does supplier have
  const [body_quantity, setBodyQuantity] = useState(0);

  const init = async () => {
       let temp = await blockchain.contract.methods
         .getManufacturerID(blockchain.userAccount)
         .call(); //gets all data
         setID(temp.tag);
         set_wheel_sup(temp.wheel_supplier);
         set_body_sup(temp.body_supplier);
        console.log(temp);
        let temp1 = await blockchain.contract.methods.getAuctionState(temp.wheel_supplier).call();
        if (temp1 == 1) setWAucState("NOT_RUNNING");
        else if (temp1 == 2) setWAucState("BIDDING");
        else if (temp1 == 3) setWAucState("REVEALING");
        console.log(temp1);
        let temp2 = await blockchain.contract.methods.getAuctionState(temp.body_supplier).call();
        if (temp2 == 1) setBAucState("NOT_RUNNING");
        else if (temp2 == 2) setBAucState("BIDDING");
        else if (temp2 == 3) setBAucState("REVEALING");
        console.log(temp2);
    
};

  useEffect(() => {
    init();
  }, [blockchain]);
 
  return (<div>
    <h1>Welcome Manufacturer!</h1>;
    </div>)
}
