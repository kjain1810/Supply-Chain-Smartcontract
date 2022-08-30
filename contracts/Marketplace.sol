pragma solidity >=0.8.16;

import {FirstAuction} from "./auction.sol";

contract Marketplace {
    enum AuctionState {
        RUNNING, // auction is running and bids are being places
        REVEALING, // auction has ended and bidders are revealing their bids
        NOT_STARTED, // auction hasn't started yet
        FINISHED // auction has finished
    }

    struct Bid {
        uint256 valuePrice;
        uint256 valueQuantity;
        address payable bidderAddress;
        bytes32 blindBidPrice; // will have price and quantity you are bidding
        bytes32 blindBidQuantity;
        uint256 limitingResourceQuantity;
        uint256 buyerID;
        uint256 sellerID;
    }

    uint256 public num_supplier;
    uint256 public num_manufacturer;
    uint256 public num_customer;

    mapping(uint256 => Supplier) public suppliers;
    mapping(uint256 => Manufacturer) public manufacturers;
    mapping(uint256 => Customer) public customers;
    mapping(address => Bid[]) bidsTillNow;

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        num_manufacturer = 0;
        num_supplier = 0;
        num_customer = 0;
    }

    struct Supplier {
        uint256 tag;
        int256 partType;
        uint256 quantityAvailable;
        AuctionState currentState;
        address wallet;
        uint256 maxBidders;
        uint256 bidsPlaced;
        uint256 bidsRevealed;
    }

    struct Manufacturer {
        uint256 _tag;
        uint256 quantityA;
        uint256 quantityB;
        uint256 cars;
        AuctionState currentState;
        address wallet;
        uint256 maxBidders;
    }

    struct Customer {
        uint256 _tag;
        address wallet;
    }

    // function makeBidSupplier(int index, ...) public {
    //     suppliers[index].auction.makeBid(...);
    // }
    // Helpers
    function minimum(uint256 a, uint256 b) public pure returns (uint256) {
        return a >= b ? b : a;
    }

    function supplierStartAuction(uint256 tag) public returns (uint256) {
        // function for supplier to start their bidding process
        require(tag <= num_supplier, "User doesn't exist");
        require(
            suppliers[tag].currentState != AuctionState.RUNNING,
            "Auction in-progress already"
        );

        // TODO: UNCOMMENT THE FOLLOWING TO ENSURE PEOPLE ARE STARTING AUCTIONS FOR THEMSELVES ONLY
        // require(suppliers[tag].wallet == msg.sender, "Start auction only for yourself!");

        suppliers[tag].currentState = AuctionState.RUNNING;
        suppliers[tag].bidsPlaced = 0;
        suppliers[tag].bidsRevealed = 0;
        emit StartSupplierAuction(tag, block.timestamp);
        return block.timestamp;
    }

    function supplierEndAuction(uint256 tag) public returns (uint256) {
        // function for suppilier to end their auction
        require(tag <= num_supplier, "User doesn't exist");
        require(
            suppliers[tag].currentState == AuctionState.RUNNING,
            "Auction ended already"
        );

        // TODO: UNCOMMENT THE FOLLOWING TO ENSURE PEOPLE ARE ENDING AUCTIONS FOR THEMSELVES ONLY
        // require(suppliers[tag].wallet == msg.sender, "End auction only for yourself!");

        suppliers[tag].currentState = AuctionState.REVEALING;
        suppliers[tag].bidsRevealed = 0;
        emit EndSupplierAuction(tag, block.timestamp);
        return block.timestamp;
    }

    function manufacturerPlacesBid(
        uint256 manufacturerID,
        uint256 supplierID,
        bytes32 blindPrice,
        bytes32 blindQuantity,
        uint256 limit
    )
        public
        beforeOnly(supplierEndAuction(supplierID))
        afterOnly(supplierEndAuction(supplierID))
    {
        //should get all data needed for bid
        // function for manufacturer to place a bid
        //@please check price and quant hashing part @checked
        require(
            num_manufacturer >= manufacturerID,
            "Manufacturer doesn't exist"
        );
        require(num_supplier >= supplierID, "Supplier doesn't exist");
        require(
            suppliers[supplierID].currentState == AuctionState.RUNNING,
            "Supplier isn't running an auction right now"
        );

        // TODO: UNCOMMENT THE FOLLOWING TO ENSURE PEOPLE ARE ONLY PLACING BIDS FOR THEMSELVES
        // require(manufacturers[manufacturerID].wallet == msg.sender, "You can only bid for yourself!");

        Bid memory newbid;
        newbid.bidderAddress = payable(msg.sender);
        newbid.buyerID = manufacturerID;
        newbid.sellerID = supplierID;
        newbid.blindBidPrice = blindPrice;
        newbid.blindBidQuantity = blindQuantity;
        newbid.limitingResourceQuantity = limit;
        newbid.valuePrice = 0;
        newbid.valueQuantity = 0;

        address supplieraddr = suppliers[supplierID].wallet;
        bidsTillNow[supplieraddr].push(newbid);

        suppliers[supplierID].bidsPlaced += 1;

        emit ManufacturerBids(
            supplierID,
            manufacturerID,
            newbid.blindBidPrice,
            newbid.blindBidQuantity
        );

        if (
            suppliers[supplierID].bidsPlaced == suppliers[supplierID].maxBidders
        ) {
            // go to reveal phase
        }
    }

    function customerPlacesBid(uint256 manufacturerID, uint256 supplierID)
        public
    {
        // function for customer to place a bid
    }

    function manufactuerRevealBid(uint256 manufacturerID) public {}

    function customerRevealBid(uint256 manufacturerID) public {}

    function allBidsPlacedForSupplier(uint256 suppliedID) private {
        // once all bids have been placed, decide how much goes to each bidder
    }

    function allBidsPlacedForManufacturer(uint256 manufacturerID) private {
        // once all bids have been placed, decide how much goes to each bidder
    }

    function addSupplier(
        int256 partType,
        uint256 quantityAvailable,
        address payable addr,
        uint256 auctionBidders
    ) public {
        num_supplier++;
        suppliers[num_supplier] = Supplier(
            num_supplier,
            partType,
            quantityAvailable,
            AuctionState.NOT_STARTED,
            addr,
            auctionBidders,
            0,
            0
        );
    }

    function addManufacturer(address payable addr, uint256 auctionBidders)
        public
    {
        num_manufacturer++;
        manufacturers[num_manufacturer] = Manufacturer(
            num_manufacturer,
            0,
            0,
            0,
            AuctionState.NOT_STARTED,
            addr,
            auctionBidders
        );
    }

    function addCustomer(address payable addr) public {
        num_customer++;
        customers[num_customer] = Customer(num_customer, addr);
    }

    // Setter functions
    function supplierAddQuantity(uint256 suppliedID, uint256 quantityToAdd)
        public
    {
        require(suppliers[suppliedID].wallet == msg.sender);
        require(num_supplier >= suppliedID);
        // increase the supplier quantity
        suppliers[suppliedID].quantityAvailable += quantityToAdd;
    }

    function Update_Manufacturer_Quantities(
        uint256 manufacturerID,
        uint256 quantityA,
        uint256 quantityB
    ) private {
        manufacturers[manufacturerID].quantityA += quantityA;
        manufacturers[manufacturerID].quantityB += quantityB;
        uint256 max_cars = minimum(quantityA, quantityB);
        manufacturers[manufacturerID].quantityA -= max_cars;
        manufacturers[manufacturerID].quantityB -= max_cars;
        manufacturers[manufacturerID].cars += max_cars;
    }

    event StartSupplierAuction(uint256 supplierID, uint256 startTime);
    event EndSupplierAuction(uint256 supplierID, uint256 endTime);

    event StartManufacturerAuction(uint256 manufacturerID, uint256 startTime);
    event EndManufacturerAuction(uint256 manufacturerID, uint256 endTime);

    // Manufacturer places a bid to the supplier
    event ManufacturerBids(
        uint256 supplierID,
        uint256 manufacturerID,
        bytes32 blindBidPrice,
        bytes32 blindBidQuantity
    );
    // Manufacturer reveals it's bid to the supplier by providing the key
    event ManufacturerReveal();

    // Customer places a bid to the manufacturer
    event CustomerBid(
        uint256 manufacturerID,
        uint256 customerID,
        bytes32 blindBid
    );
    event CustomerReveal();

    // ALL GET FUNCTIONS
    function getCustomers() public view returns (address[200] memory) {
        address[200] memory ret;
        for (uint256 i = 1; i <= num_customer; i += 1)
            ret[i] = customers[i].wallet;
        return ret;
    }

    // all modifiers
    modifier beforeOnly(uint256 _time) {
        require(block.timestamp < _time);
        _;
    }
    modifier afterOnly(uint256 _time) {
        require(block.timestamp > _time);
        _;
    }
}
