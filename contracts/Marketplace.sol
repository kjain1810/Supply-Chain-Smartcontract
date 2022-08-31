pragma solidity >=0.8.16;
pragma experimental ABIEncoderV2;

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
        bool correctReveal;
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
        // require(
        //     suppliers[tag].wallet == msg.sender,
        //     "Start auction only for yourself!"
        // );

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
        // require(
        //     suppliers[tag].wallet == msg.sender,
        //     "End auction only for yourself!"
        // );

        suppliers[tag].currentState = AuctionState.REVEALING;
        suppliers[tag].bidsRevealed = 0;
        emit EndSupplierAuction(tag, block.timestamp);
        return block.timestamp;
    }

    function supplierEndReveal(uint256 tag) public returns (uint256) {
        require(tag <= num_supplier, "Supplier doesn't exist");
        require(
            suppliers[tag].currentState == AuctionState.REVEALING,
            "Reveal phase not running"
        );

        // TODO: UNCOMMENT THE FOLLOWING TO ENSURE PEOPLE ARE ALLOCATING FOR THEMSELVES ONLY
        // require(
        //     (suppliers[tag].wallet == msg.sender || owner == msg.sender),
        //     "Operation now allowed"
        // );

        suppliers[tag].currentState = AuctionState.FINISHED;

        // do allocation logic and emit

        // bubble sort according to bid value
        for (uint256 i = 0; i < bidsTillNow[suppliers[tag].wallet].length; i++)
            for (uint256 j = 0; j < i; j++)
                if (
                    bidsTillNow[suppliers[tag].wallet][i].valuePrice <
                    bidsTillNow[suppliers[tag].wallet][j].valuePrice
                ) {
                    Bid memory x = bidsTillNow[suppliers[tag].wallet][i];
                    bidsTillNow[suppliers[tag].wallet][i] = bidsTillNow[
                        suppliers[tag].wallet
                    ][j];
                    bidsTillNow[suppliers[tag].wallet][j] = x;
                }
        // allocate according to limiting resource first
        uint256[100] memory allocatingPrices;
        uint256[100] memory allocatingQuantities;
        for (
            uint256 i = 0;
            i < bidsTillNow[suppliers[tag].wallet].length;
            i++
        ) {
            Bid memory bid = bidsTillNow[suppliers[tag].wallet][i];
            uint256 allocatingHere = minimum(
                suppliers[tag].quantityAvailable,
                bid.limitingResourceQuantity
            );
            allocatingHere = minimum(allocatingHere, bid.valueQuantity);

            allocatingPrices[bid.buyerID] = bid.valuePrice;
            allocatingQuantities[bid.buyerID] = allocatingHere;
            suppliers[tag].quantityAvailable -= allocatingHere;
            bid.valueQuantity -= allocatingHere;
        }

        // allocate remaining for maximum profit
        for (
            uint256 i = 0;
            i < bidsTillNow[suppliers[tag].wallet].length;
            i++
        ) {
            Bid memory bid = bidsTillNow[suppliers[tag].wallet][i];
            uint256 allocatingHere = minimum(
                suppliers[tag].quantityAvailable,
                bid.valueQuantity
            );

            allocatingQuantities[bid.buyerID] += allocatingHere;
            suppliers[tag].quantityAvailable -= allocatingHere;
            bid.valueQuantity -= allocatingHere;
        }

        // emit all allocations
        for (uint256 i = 0; i < 100; i++)
            if (allocatingQuantities[i] > 0) {
                emit AllocateFromSupplier(
                    tag,
                    i,
                    allocatingQuantities[i],
                    allocatingPrices[i]
                );
                transferMoney(
                    suppliers[tag].wallet,
                    manufacturers[i].wallet,
                    allocatingPrices[i],
                    allocatingQuantities[i]
                );
            }
        return block.timestamp;
    }

    function transferMoney(
        address senderaddr,
        address receiveraddr,
        uint256 price,
        uint256 qunatity
    ) private {
        // do eth transactions here
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
        // require(
        //     manufacturers[manufacturerID].wallet == msg.sender,
        //     "You can only bid for yourself!"
        // );

        Bid memory newbid;
        newbid.bidderAddress = payable(msg.sender);
        newbid.buyerID = manufacturerID;
        newbid.sellerID = supplierID;
        newbid.blindBidPrice = blindPrice;
        newbid.blindBidQuantity = blindQuantity;
        newbid.limitingResourceQuantity = limit;
        newbid.valuePrice = 0;
        newbid.valueQuantity = 0;
        newbid.correctReveal = true;

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
            suppliers[supplierID].currentState = AuctionState.REVEALING;
        }
    }

    function customerPlacesBid(uint256 manufacturerID, uint256 supplierID)
        public
    {
        // function for customer to place a bid
    }

    function manufactuerRevealBid(
        uint256 manufacturerID,
        uint256 supplierID,
        uint256 price,
        uint256 quantity
    ) public returns (bool) {
        require(manufacturerID <= num_manufacturer, "Invalid manufacturer");

        // TODO: UNCOMMENT THE FOLLOWING TO ENSURE PEOPLE ARE ONLY REVEALING BIDS FOR THEMSELVES
        // require(
        //     manufacturers[manufacturerID].wallet == msg.sender,
        //     "Reveal only for yourself!"
        // );

        for (
            uint256 i = 0;
            i < bidsTillNow[suppliers[supplierID].wallet].length;
            i++
        )
            if (
                bidsTillNow[suppliers[supplierID].wallet][i].buyerID ==
                manufacturerID
            ) {
                if (
                    keccak256(abi.encodePacked(price)) !=
                    bidsTillNow[suppliers[supplierID].wallet][i].blindBidPrice
                ) {
                    bidsTillNow[suppliers[supplierID].wallet][i]
                        .correctReveal = false;
                    return false;
                }
                if (
                    keccak256(abi.encodePacked(quantity)) !=
                    bidsTillNow[suppliers[supplierID].wallet][i]
                        .blindBidQuantity
                ) {
                    bidsTillNow[suppliers[supplierID].wallet][i]
                        .correctReveal = false;
                    return false;
                }
                bidsTillNow[suppliers[supplierID].wallet][i].valuePrice = price;
                bidsTillNow[suppliers[supplierID].wallet][i]
                    .valueQuantity = quantity;
                emit ManufacturerReveal(
                    supplierID,
                    manufacturerID,
                    price,
                    quantity
                );

                suppliers[supplierID].bidsRevealed += 1;
                if (
                    suppliers[supplierID].bidsRevealed ==
                    suppliers[supplierID].maxBidders
                ) {
                    // go to allocation
                    supplierEndReveal(supplierID);
                }

                return true;
            }
        return false;
    }

    function customerRevealBid(uint256 manufacturerID) public {}

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

    // Starting, ending and allocation of auction by supplier
    event StartSupplierAuction(uint256 supplierID, uint256 startTime);
    event EndSupplierAuction(uint256 supplierID, uint256 endTime);
    event AllocateFromSupplier(
        uint256 supplierID,
        uint256 manufacturerID,
        uint256 quantity,
        uint256 price
    );

    // Starting, ending and allocation of auctions by manufacturers
    event StartManufacturerAuction(uint256 manufacturerID, uint256 startTime);
    event EndManufacturerAuction(uint256 manufacturerID, uint256 endTime);
    event AllocateFromManufacturer(
        uint256 manufacturerID,
        uint256 customerID,
        uint256 quantity,
        uint256 price
    );

    // Manufacturer places a bid to the supplier
    event ManufacturerBids(
        uint256 supplierID,
        uint256 manufacturerID,
        bytes32 blindBidPrice,
        bytes32 blindBidQuantity
    );
    // Manufacturer reveals it's bid to the supplier by providing the key
    event ManufacturerReveal(
        uint256 supplierID,
        uint256 manufacturerID,
        uint256 price,
        uint256 quantity
    );

    // Customer places a bid to the manufacturer
    event CustomerBid(
        uint256 manufacturerID,
        uint256 customerID,
        bytes32 blindBid
    );
    event CustomerReveal(
        uint256 manufacturerID,
        uint256 customerID,
        uint256 price,
        uint256 quantity
    );

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
