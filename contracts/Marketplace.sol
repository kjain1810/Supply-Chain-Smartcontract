pragma solidity >=0.8.16;

import { FirstAuction } from "./auction.sol";

contract Marketplace {

    enum AuctionState {RUNNING, NOT_STARTED, FINISHED}

    struct Bid {
        uint256 valuePrice;
        uint256 valueQuantity;
        address payable bidderAddress;
        bytes32 blindBidPrice; // will have price and quantity you are bidding  
        bytes32 blindBidQuantity;
        uint limitingResourceQuantity;
        uint buyerID;
        uint sellerID;
    }

    uint public num_supplier;
    uint public num_manufacturer;
    uint public num_customer;

    mapping (uint => Supplier) public suppliers;
    mapping (uint => Manufacturer) public manufacturers;
    mapping (uint => Customer) public customers;
    mapping (address => Bid[]) bidsTillNow;
    
    

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        num_manufacturer = 0;
        num_supplier = 0;
        num_customer = 0;                
    }

    struct Supplier {
        uint tag;
        int partType;
        uint quantityAvailable;
        AuctionState currentState;
        address wallet;
        uint maxBidders;
        
    }

    struct Manufacturer {
        uint _tag;
        uint quantityA;
        uint quantityB;
        uint cars;
        AuctionState currentState;
        address wallet;
        uint maxBidders;
    }

    struct Customer {
        uint _tag;
        address wallet;
    }

    // function makeBidSupplier(int index, ...) public {
    //     suppliers[index].auction.makeBid(...);
    // }
    // Helpers
    function minimum(uint a, uint b) public pure returns (uint) {
    return a >= b ? b : a;
    }

    function supplierStartAuction (uint tag) public returns (uint) {
        // function for supplier to start their bidding process
        require(tag<=num_supplier,"User doesn't exist");
        require(suppliers[tag].currentState != AuctionState.RUNNING, "Auction in-progress already");
        suppliers[tag].currentState = AuctionState.RUNNING ;
        emit StartSupplierAuction (tag, block.timestamp);
        return block.timestamp;
    
    }

    function supplierEndAuction (uint tag) public returns (uint){
        // function for suppilier to end their auction
        require(tag<=num_supplier,"User doesn't exist");
        require(suppliers[tag].currentState == AuctionState.RUNNING, "Auction Ended Already");
        suppliers[tag].currentState = AuctionState.FINISHED;
        emit EndSupplierAuction (tag, block.timestamp);
        return block.timestamp;
    }
 

    function manufacturerPlacesBid(uint manufacturerID, uint supplierID , uint price, uint quant, uint limit) public beforeOnly(supplierEndAuction(supplierID)) afterOnly(supplierEndAuction(supplierID)){ //should get all data needed for bid
        // function for manufacturer to place a bid
        //@please check price and quant hashing part
        require(num_manufacturer >= manufacturerID, "Manufacturer doesn't exist");
        require(num_supplier >= supplierID, "Supplier doesn't exist");
        Bid memory newbid;
        newbid.bidderAddress = payable(msg.sender);
        newbid.buyerID = manufacturerID;
        newbid.sellerID = supplierID;
       // newbid.blindBidPrice = price;
       // newbid.blindBidQuantity = quant;
        newbid.limitingResourceQuantity = limit;
        address supplieraddr = suppliers[supplierID].wallet;
        bidsTillNow[supplieraddr].push(newbid) ;
        
        emit ManufacturerBids(supplierID, manufacturerID, newbid.blindBidPrice, newbid.blindBidQuantity);

    }

    function customerPlacesBid(uint manufacturerID, uint supplierID) public {
        // function for customer to place a bid        
    }

    function manufactuerRevealBid(uint manufacturerID) public {

    }

    function customerRevealBid(uint manufacturerID) public {
        
    }

    function allBidsPlacedForSupplier(uint suppliedID) private {
        // once all bids have been placed, decide how much goes to each bidder
    }

    function allBidsPlacedForManufacturer(uint manufacturerID) private {
        // once all bids have been placed, decide how much goes to each bidder
    }

    function addSupplier(int partType, uint quantityAvailable, address payable addr, uint auctionBidders) public {
        num_supplier++;
        suppliers[num_supplier] = Supplier(num_supplier, partType, quantityAvailable, AuctionState.NOT_STARTED, addr, auctionBidders);
    }

    function addManufacturer(address payable addr, uint auctionBidders) public {
        num_manufacturer++;
        manufacturers[num_manufacturer] = Manufacturer(num_manufacturer, 0, 0,0, AuctionState.NOT_STARTED, addr, auctionBidders);
    }

    function addCustomer(address payable addr) public {
        num_customer++;
        customers[num_customer] = Customer(num_customer, addr);
    }

    // Setter functions
    function supplierAddQuantity(uint suppliedID, uint quantityToAdd) public {
        require(suppliers[suppliedID].wallet == msg.sender);
        require(num_supplier>=suppliedID);
        // increase the supplier quantity
        suppliers[suppliedID].quantityAvailable+=quantityToAdd;
    }

    function Update_Manufacturer_Quantities(uint manufacturerID, uint quantityA , uint quantityB) private {
        manufacturers[manufacturerID].quantityA+=quantityA;
        manufacturers[manufacturerID].quantityB+=quantityB;
        uint max_cars= minimum(quantityA, quantityB);
        manufacturers[manufacturerID].quantityA-=max_cars;
        manufacturers[manufacturerID].quantityB-=max_cars;
        manufacturers[manufacturerID].cars+=max_cars;
    }

    event StartSupplierAuction(uint supplierID, uint startTime);
    event EndSupplierAuction(uint supplierID, uint endTime);

    event StartManufacturerAuction(uint manufacturerID, uint startTime);
    event EndManufacturerAuction(uint manufacturerID, uint endTime);
    
    // Manufacturer places a bid to the supplier
    event ManufacturerBids(uint supplierID, uint manufacturerID, bytes32 blindBidPrice, bytes32 blindBidQuantity);
    // Manufacturer reveals it's bid to the supplier by providing the key
    event ManufacturerReveal();
    
    // Customer places a bid to the manufacturer
    event CustomerBid(uint manufacturerID,uint customerID, bytes32 blindBid);
    event CustomerReveal();



    // ALL GET FUNCTIONS
    function getCustomers() public view returns (address[200] memory){
        address[200] memory ret;
        for (uint i = 1; i <= num_customer; i+=1)
            ret[i] = customers[i].wallet;
        return ret;        
    }

   

    // all modifiers
    modifier beforeOnly(uint _time) { require(block.timestamp < _time); _; }
    modifier afterOnly(uint _time) { require(block.timestamp > _time); _; }

    
}