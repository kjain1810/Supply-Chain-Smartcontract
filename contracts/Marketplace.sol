// SPDX-License-Identifier: MIT
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

    struct Purchase {
        uint256 sellerID;
        uint256 buyerID;
        uint256 quantity;
        address payable customeraddr;
        uint256 money;
    }

    struct Product {
        uint256 tag;
        uint256 manufacturerID;
        uint256 sellerA; //wheels
        uint256 sellerB; //car_body
    }

    uint256 public num_supplier;
    uint256 public num_manufacturer;
    uint256 public num_customer;
    uint256 public num_products;

    mapping(uint256 => Supplier) public suppliers;
    mapping(uint256 => Manufacturer) public manufacturers;
    mapping(uint256 => Customer) public customers;
    mapping(address => Bid[]) bidsTillNow;
    mapping(address => Purchase[]) purchasesTillNow;
    mapping(address => Product[]) productsTillNow;

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        num_manufacturer = 0;
        num_supplier = 0;
        num_customer = 0;
    }

    struct Supplier {
        uint256 tag;
        int256 partType; // 0 is wheels, 1 is car_parts
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
        uint256 carsprice;
        AuctionState currentState;
        address wallet;
        uint256 maxBidders;
        uint256 QA_sellerID;
        uint256 QB_sellerID;
    }

    mapping(uint256 => Car[]) carsBought;

    struct Car {
        uint256 tag;
        uint256 manufacturerID;
        uint256 sellerIDA;
        uint256 sellerIDB;
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

    function supplierEndReveal(uint256 tag)
        public
        returns (
            // afterOnly(supplierEndAuction(tag))
            uint256
        )
    {
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
            bidsTillNow[suppliers[tag].wallet][i]
                .valueQuantity -= allocatingHere;
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
            bidsTillNow[suppliers[tag].wallet][i]
                .valueQuantity -= allocatingHere;
        }

        // emit all allocations
        for (uint256 i = 1; i <= num_manufacturer; i++)
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
                //update all the manufacturers quanitites to make cars
                if (suppliers[tag].partType == 1)
                    update_Manufacturer_Quantities(
                        i,
                        allocatingQuantities[i],
                        0,
                        tag,
                        0
                    );
                else if (suppliers[tag].partType == 2)
                    update_Manufacturer_Quantities(
                        i,
                        0,
                        allocatingQuantities[i],
                        0,
                        tag
                    );
                else revert();
            }
        while (bidsTillNow[suppliers[tag].wallet].length > 0)
            bidsTillNow[suppliers[tag].wallet].pop();
        return block.timestamp;
    }

    function transferMoney(
        address senderaddr,
        address receiveraddr,
        uint256 price,
        uint256 qunatity
    ) private {
        // do eth transactions here
        return;
    }

    function refundMoney(address beneficary, uint256 price) private {
        // do eth transactions here
    }

    function manufacturerPlacesBid(
        uint256 manufacturerID,
        uint256 supplierID,
        bytes32 blindPrice,
        bytes32 blindQuantity,
        uint256 limit // beforeOnly(supplierEndAuction(supplierID)) // afterOnly(supplierEndAuction(supplierID))
    ) public {
        //should get all data needed for bid
        // function for manufacturer to place a bid
        require(
            num_manufacturer >= manufacturerID,
            "Manufacturer doesn't exist"
        );
        require(num_supplier >= supplierID, "Supplier doesn't exist");
        require(
            suppliers[supplierID].currentState == AuctionState.RUNNING,
            "Supplier isn't running an auction right now"
        );
        require(
            supplierID == manufacturerID || supplierID == 3,
            "Supplier doesnt sell you"
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
            blindPrice,
            blindQuantity
        );

        // if (
        //     suppliers[supplierID].bidsPlaced == suppliers[supplierID].maxBidders
        // ) {
        //     // go to reveal phase
        //     suppliers[supplierID].currentState = AuctionState.REVEALING;
        //     supplierEndAuction()
        // }
    }

    function customerPurchase(
        uint256 customerID,
        uint256 manufacturerID,
        uint256 quantity
    ) external payable {
        require(
            customers[customerID].wallet == msg.sender || owner == msg.sender,
            "Access Denied"
        );
        Purchase memory newpurchase;
        newpurchase.sellerID = manufacturerID;
        newpurchase.customeraddr = payable(msg.sender);
        newpurchase.quantity = quantity;
        newpurchase.buyerID = customerID;
        newpurchase.money = msg.value;
        uint256 unit_cost = manufacturers[manufacturerID].carsprice;
        uint256 total_cost = unit_cost * quantity;
        require(newpurchase.money >= total_cost, "Money not enough");
        address manf_adrr = manufacturers[manufacturerID].wallet;
        purchasesTillNow[manf_adrr].push(newpurchase);
        emit CustomerRequest(
            customerID,
            manufacturerID,
            quantity,
            manufacturers[manufacturerID].carsprice
        );
    }

    function manufactuerRevealBid(
        uint256 manufacturerID,
        uint256 supplierID,
        uint256 price,
        uint256 quantity
    ) public returns (bool) {
        require(manufacturerID <= num_manufacturer, "Invalid manufacturer");
        require(suppliers[supplierID].currentState == AuctionState.REVEALING);
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
                require(
                    keccak256(abi.encodePacked(price)) ==
                        bidsTillNow[suppliers[supplierID].wallet][i]
                            .blindBidPrice,
                    "Incorrect price"
                );
                require(
                    keccak256(abi.encodePacked(quantity)) ==
                        bidsTillNow[suppliers[supplierID].wallet][i]
                            .blindBidQuantity,
                    "Incorrect quantity"
                );
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
                    // supplierEndReveal(supplierID);
                }

                return true;
            }
        return false;
    }

    function manufacturerSupplyCars(uint256 manufacturerID) private {
        require(num_manufacturer >= manufacturerID);
        require(
            msg.sender == manufacturers[manufacturerID].wallet ||
                msg.sender == owner
        );
        for (
            uint256 i = 0;
            i < purchasesTillNow[manufacturers[manufacturerID].wallet].length;
            i++
        ) {
            //Money is already checked, Quantity check is done here
            if (
                purchasesTillNow[manufacturers[manufacturerID].wallet][i]
                    .quantity <= manufacturers[manufacturerID].cars
            ) {
                uint256 effective_price = purchasesTillNow[
                    manufacturers[manufacturerID].wallet
                ][i].quantity * manufacturers[manufacturerID].carsprice;
                uint256 refund_amount = purchasesTillNow[
                    manufacturers[manufacturerID].wallet
                ][i].money - effective_price;

                manufacturers[manufacturerID].cars -= purchasesTillNow[
                    manufacturers[manufacturerID].wallet
                ][i].quantity;
                uint256 num_of_cars = purchasesTillNow[
                    manufacturers[manufacturerID].wallet
                ][i].quantity;
                address mf_adrr = manufacturers[manufacturerID].wallet;
                for (uint256 j = 0; j < num_of_cars; j++) {
                    uint256 idx = productsTillNow[mf_adrr].length - 1;
                    Car memory newcar;
                    newcar.tag = productsTillNow[mf_adrr][idx].tag;
                    newcar.manufacturerID = manufacturerID;
                    newcar.sellerIDA = productsTillNow[mf_adrr][idx].sellerA;
                    newcar.sellerIDB = productsTillNow[mf_adrr][idx].sellerB;
                    carsBought[purchasesTillNow[mf_adrr][idx].buyerID].push(
                        newcar
                    );
                    productsTillNow[mf_adrr].pop();
                }
                transferMoney(
                    customers[
                        purchasesTillNow[manufacturers[manufacturerID].wallet][
                            i
                        ].buyerID
                    ].wallet,
                    manufacturers[manufacturerID].wallet,
                    effective_price,
                    purchasesTillNow[manufacturers[manufacturerID].wallet][i]
                        .quantity
                );
                // refundMoney(
                // customers[purchasesTillNow[manufacturers[manufacturerID].wallet][i].buyerID].wallet,
                // refund_amount);
                emit AllocateFromManufacturer(
                    manufacturerID,
                    purchasesTillNow[manufacturers[manufacturerID].wallet][i]
                        .buyerID,
                    purchasesTillNow[manufacturers[manufacturerID].wallet][i]
                        .quantity,
                    effective_price
                );
            } else {
                //send them back the amount saying quantity not available
                revert("Quantity not Available"); //gas to caller
            }
        }
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
            0,
            AuctionState.NOT_STARTED,
            addr,
            auctionBidders,
            0,
            0
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

    function update_Manufacturer_Quantities(
        uint256 manufacturerID,
        uint256 quantityA,
        uint256 quantityB,
        uint256 supplierA,
        uint256 supplierB
    ) private {
        manufacturers[manufacturerID].quantityA += quantityA;
        manufacturers[manufacturerID].quantityB += quantityB;
        uint256 max_cars = minimum(
            manufacturers[manufacturerID].quantityA,
            manufacturers[manufacturerID].quantityB
        );
        manufacturers[manufacturerID].quantityA -= max_cars;
        manufacturers[manufacturerID].quantityB -= max_cars;
        manufacturers[manufacturerID].cars += max_cars;

        Product memory newcar;
        num_products++;
        newcar.tag = num_products;
        newcar.manufacturerID = manufacturerID;
        newcar.sellerA = manufacturerID;
        newcar.sellerB = 3;
        productsTillNow[manufacturers[manufacturerID].wallet].push(newcar);
    }

    function set_cars_price(uint256 manufacturerID, uint256 price) public {
        require(
            msg.sender == manufacturers[manufacturerID].wallet ||
                msg.sender == owner,
            "Cannot be set by you"
        );
        manufacturers[manufacturerID].carsprice = price;
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
    event CustomerRequest(
        uint256 CustomerID,
        uint256 ManufacturerID,
        uint256 Quantity,
        uint256 Price
    );
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
    function getActors() public view returns (address[200] memory) {
        address[200] memory ret;
        uint256 idx = 0;
        for (uint256 i = 1; i <= num_supplier; i += 1)
            ret[idx++] = suppliers[i].wallet;
        for (uint256 i = 1; i <= num_manufacturer; i += 1)
            ret[idx++] = manufacturers[i].wallet;
        for (uint256 i = 1; i <= num_customer; i += 1)
            ret[idx++] = customers[i].wallet;
        return ret;
    }

    function getBids() public view returns (uint256[50] memory) {
        uint256[50] memory ret;
        uint256 idx = 0;
        for (uint256 i = 1; i <= num_supplier; i++) {
            for (
                uint256 j = 0;
                j < bidsTillNow[suppliers[i].wallet].length;
                j++
            ) {
                ret[idx++] = bidsTillNow[suppliers[i].wallet][j].buyerID;
                ret[idx++] = bidsTillNow[suppliers[i].wallet][j].sellerID;
                ret[idx++] = bidsTillNow[suppliers[i].wallet][j].valueQuantity;
                ret[idx++] = bidsTillNow[suppliers[i].wallet][j].valuePrice;
                ret[idx++] = bidsTillNow[suppliers[i].wallet][j]
                    .limitingResourceQuantity;
                idx++;
            }
        }
        return ret;
    }

    function verifyproduct(uint256 customerID, uint256 car_tag)
        public
        view
        returns (
            uint256 a,
            uint256 b,
            uint256 c
        )
    {
        for (uint256 i = 0; i < carsBought[customerID].length; i++) {
            if (carsBought[customerID][i].tag == car_tag)
                return (
                    carsBought[customerID][i].manufacturerID,
                    carsBought[customerID][i].sellerIDA,
                    carsBought[customerID][i].sellerIDB
                );
        }
    }

    //everyone can access it
    function get_cars_price_quantity(uint256 manfID)
        public
        view
        returns (uint256 a, uint256 b)
    {
        require(num_manufacturer >= manfID, "Manufacturer ID doesnot exist");
        return (manufacturers[manfID].carsprice, manufacturers[manfID].cars);
    }

    function get_manufacturer_data(uint256 manfID)
        public
        view
        returns (
            uint256 tag,
            uint256 quantA,
            uint256 quantB,
            uint256 cars
        )
    {
        Manufacturer memory t = manufacturers[manfID];
        return (t._tag, t.quantityA, t.quantityB, t.cars);
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

    //test only
    function set_cars(uint256 manfID, uint256 quant) public {
        manufacturers[manfID].cars = quant;
    }
}
