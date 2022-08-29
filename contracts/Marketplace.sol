pragma solidity >=0.8.16;

contract Marketplace {

    enum AuctionState {RUNNING, NOT_STARTED, FINISHED}

    uint num_supplier;
    uint num_manufacturer;
    uint num_customer;

    mapping (uint => Supplier) public suppliers;
    mapping (uint => Manufacturer) public manufacturers;
    mapping (uint => Customer) public customers;

    constructor() {
        num_manufacturer = 0;
        num_supplier = 0;                
    }

    struct Supplier {
        int tag;
        int partType;
        uint quantityAvailable;
        AuctionState currentState;
    }

    struct Manufacturer {
        int _tag;
        uint quantityA;
        uint quantityB;
        AuctionState currentState;
    }

    struct Customer {
        int _tag;
    }

    function addSupplier(int tag, int partType, uint quantityAvailable) public {
        num_supplier++;
        suppliers[num_supplier] = Supplier(tag, partType, quantityAvailable, AuctionState.NOT_STARTED);
    }

    function addManufacturer(int tag) public {
        num_manufacturer++;
        manufacturers[num_manufacturer] = Manufacturer(tag, 0, 0, AuctionState.NOT_STARTED);
    }

    function addCustomer(int tag) public {
        num_customer++;
        customers[num_customer] = Customer(tag);
    }
}