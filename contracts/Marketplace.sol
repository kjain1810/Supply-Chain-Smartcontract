pragma solidity >=0.8.16;

import { FirstAuction } from "./auction.sol";

contract Marketplace {

    enum AuctionState {RUNNING, NOT_STARTED, FINISHED}

    uint num_supplier;
    uint num_manufacturer;
    uint num_customer;

    mapping (uint => Supplier) public suppliers;
    mapping (uint => Manufacturer) public manufacturers;
    mapping (uint => Customer) public customers;

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        num_manufacturer = 0;
        num_supplier = 0;                
    }

    struct Supplier {
        uint tag;
        int partType;
        uint quantityAvailable;
        AuctionState currentState;
        address wallet;
        uint maxBidders;
        FirstAuction auction;
    }

    struct Manufacturer {
        uint _tag;
        uint quantityA;
        uint quantityB;
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

    function addSupplier(int partType, uint quantityAvailable, address payable addr, uint auctionBidders) public {
        num_supplier++;
        suppliers[num_supplier] = Supplier(num_supplier, partType, quantityAvailable, AuctionState.NOT_STARTED, addr, auctionBidders);
    }

    function addManufacturer(address payable addr, uint auctionBidders) public {
        num_manufacturer++;
        manufacturers[num_manufacturer] = Manufacturer(num_manufacturer, 0, 0, AuctionState.NOT_STARTED, addr, auctionBidders);
    }

    function addCustomer(address payable addr) public {
        num_customer++;
        customers[num_customer] = Customer(num_customer, addr);
    }

    event StartSupplierAuction(int supplierID, int endTime);
    event EndSupplierAuction(int supplierID, int endTime);

    event StartManufacturerAuction(int manufacturerID, int endTime);
    event EndManufacturerAuction(int manufacturerID, int endTime);
    
    // Manufacturer places a bid to the supplier
    event ManufacturerBids(int supplierID, int manufacturerID, bytes32 blindBid);
    // Manufacturer reveals it's bid to the supplier by providing the key
    event ManufacturerReveal();
    
    // Customer places a bid to the manufacturer
    event CustomerBid(int manufacturerID, int customerID, bytes32 blindBid);
    event CustomerReveal();
}