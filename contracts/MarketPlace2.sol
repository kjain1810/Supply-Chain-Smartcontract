pragma solidity >=0.8.16;
pragma experimental ABIEncoderV2;

contract NewMarketPlace {
    enum AuctionState {
        NOT_RUNNING,
        BIDDING,
        REVEALING
    }

    enum PartType {
        WHEEL,
        BODY
    }

    struct Supplier {
        uint256 tag;
        PartType partType;
        uint256 quantityAvailable;
        AuctionState currentState;
        address wallet;
        uint256 maxBidders;
        uint256 bidsPlaced;
        uint256 bidsRevealed;
    }

    struct Manufacturer {
        uint256 tag;
        uint256 wheelSupplier; // tag of supplier who supplies wheels
        uint256 wheelQuant; // number of wheels
        uint256 bodySupplier; // tag of supplier who supplies body
        uint256 bodyQuant; // number of bodies
        uint256 carsAvailable; // number of cars available
        uint256 carPrice;
        address wallet;
    }

    struct Car {
        uint256 tag;
        uint256 customerID;
        uint256 manufacturerID;
        uint256 wheelSupID;
        uint256 bodySupID;
    }

    struct Customer {
        uint256 tag;
        address wallet;
    }

    struct Bid {
        uint256 actualPrice;
        uint256 actualQuantity;
        uint256 actualKey;
        bytes32 blindPrice;
        bytes32 blindQuantity;
        bytes32 blindKey;
        uint256 limitingQuantity;
        uint256 buyerID;
        uint256 sellerID;
        uint256 moneySent;
        bool correctReveal;
        address payable bidderAddress;
    }

    address payable public owner;

    mapping(uint256 => Supplier) public suppliers;
    mapping(uint256 => Manufacturer) public manufacturers;
    mapping(uint256 => Customer) public customers;
    mapping(uint256 => Car) cars;
    mapping(address => Bid[]) bidsTillNow;

    uint256 num_supplier;
    uint256 num_manufacturer;
    uint256 num_customer;
    uint256 num_cars;

    event StartSupplierBidding(uint256 tag, uint256 timestamp);
    event StartSupplierReveal(uint256 tag, uint256 timestamp);
    event AllocateFromSupplier(
        uint256 supplierID,
        uint256 manufacturerID,
        uint256 quantity,
        uint256 price
    );
    event ManufacturerBids(
        uint256 manufacturerID,
        uint256 supplierID,
        bytes32 blindPrice,
        bytes32 blindQuantity,
        bytes32 blindKey
    );
    event ManufacturerReveal(
        uint256 manufacturerID,
        uint256 supplierID,
        uint256 actualPrice,
        uint256 actualQuantity,
        uint256 actualKey
    );
    event CarSold(uint256 carID, uint256 manufacturerID, uint256 customerID);

    constructor() {
        num_cars = 0;
        num_customer = 0;
        num_manufacturer = 0;
        num_supplier = 0;
        owner = payable(msg.sender);
    }

    function minimum(uint256 a, uint256 b) public pure returns (uint256) {
        return a >= b ? b : a;
    }

    function supplierStartBidding(uint256 tag) public returns (uint256) {
        require(tag <= num_supplier, "Invalid supplier!");
        require(suppliers[tag].currentState == AuctionState.NOT_RUNNING);
        require(msg.sender == suppliers[tag].wallet, "Incorrect tag");
        suppliers[tag].currentState = AuctionState.BIDDING;
        suppliers[tag].bidsPlaced = 0;
        suppliers[tag].bidsRevealed = 0;
        emit StartSupplierBidding(tag, block.timestamp);
        return block.timestamp;
    }

    function supplierStartReveal(uint256 tag) public returns (uint256) {
        require(tag <= num_supplier, "Invalid supplier!");
        require(suppliers[tag].currentState == AuctionState.BIDDING);
        require(msg.sender == suppliers[tag].wallet, "Incorrect tag");
        suppliers[tag].currentState = AuctionState.REVEALING;
        emit StartSupplierReveal(tag, block.timestamp);
        return block.timestamp;
    }

    function supplierEndAuction(uint256 tag) public returns (uint256) {
        require(tag <= num_supplier, "Invalid supplier!");
        require(suppliers[tag].currentState == AuctionState.REVEALING);
        require(msg.sender == suppliers[tag].wallet, "Incorrect tag");
        suppliers[tag].currentState = AuctionState.NOT_RUNNING;

        // bubble sorting the bids
        for (
            uint256 i = 0;
            i < bidsTillNow[suppliers[tag].wallet].length;
            i++
        ) {
            for (uint256 j = 0; j < i; j++)
                if (
                    bidsTillNow[suppliers[tag].wallet][i].actualPrice <
                    bidsTillNow[suppliers[tag].wallet][j].actualPrice
                ) {
                    Bid memory x = bidsTillNow[suppliers[tag].wallet][i];
                    bidsTillNow[suppliers[tag].wallet][i] = bidsTillNow[
                        suppliers[tag].wallet
                    ][j];
                    bidsTillNow[suppliers[tag].wallet][j] = x;
                }
        }

        // the allocations
        uint256[100] memory allocatingPrices;
        uint256[100] memory allocatingQuantities;
        uint256[100] memory moneySentWithBid;

        // optimal resource allocation
        for (
            uint256 i = 0;
            i < bidsTillNow[suppliers[tag].wallet].length;
            i++
        ) {
            Bid memory bid = bidsTillNow[suppliers[tag].wallet][i];
            if (bid.correctReveal == false) continue;

            moneySentWithBid[bid.buyerID] = bid.moneySent;

            uint256 allocatingHere = minimum(
                suppliers[tag].quantityAvailable,
                bid.limitingQuantity
            );
            allocatingHere = minimum(allocatingHere, bid.actualQuantity);

            allocatingPrices[bid.buyerID] = bid.actualPrice;
            allocatingQuantities[bid.buyerID] = allocatingHere;
            suppliers[tag].quantityAvailable -= allocatingHere;
            bidsTillNow[suppliers[tag].wallet][i]
                .actualQuantity -= allocatingHere;
        }

        // allocating to maximize profit
        for (
            uint256 i = 0;
            i < bidsTillNow[suppliers[tag].wallet].length;
            i++
        ) {
            Bid memory bid = bidsTillNow[suppliers[tag].wallet][i];
            if (bid.correctReveal == false) continue;
            uint256 allocatingHere = minimum(
                suppliers[tag].quantityAvailable,
                bid.actualQuantity
            );

            allocatingQuantities[bid.buyerID] += allocatingHere;
            suppliers[tag].quantityAvailable -= allocatingHere;
            bidsTillNow[suppliers[tag].wallet][i]
                .actualQuantity -= allocatingHere;
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
                // non bid money to manufacturer
                require(
                    payable(manufacturers[i].wallet).send(
                        moneySentWithBid[i] -
                            allocatingPrices[i] *
                            allocatingQuantities[i]
                    ),
                    "Transaction failed"
                );
                // bid money to supplier
                require(
                    payable(suppliers[tag].wallet).send(
                        allocatingPrices[i] * allocatingQuantities[i]
                    ),
                    "Transaction failed"
                );
                //update all the manufacturers quanitites to make cars
                if (suppliers[tag].partType == PartType.BODY) {
                    manufacturers[i].bodyQuant += allocatingQuantities[i];
                } else if (suppliers[tag].partType == PartType.WHEEL) {
                    manufacturers[i].wheelQuant += allocatingQuantities[i];
                } else revert();
                updateManufacturerCars(i);
            }
        while (bidsTillNow[suppliers[tag].wallet].length > 0)
            bidsTillNow[suppliers[tag].wallet].pop();

        return block.timestamp;
    }

    function updateManufacturerCars(uint256 tag) private {
        uint256 carsMade = minimum(
            manufacturers[tag].bodyQuant,
            manufacturers[tag].wheelQuant
        );
        manufacturers[tag].bodyQuant -= carsMade;
        manufacturers[tag].wheelQuant -= carsMade;
        manufacturers[tag].carsAvailable += carsMade;
    }

    function manufacturerPlacesBid(
        uint256 manufacturerID,
        uint256 supplierID,
        bytes32 blindPrice,
        bytes32 blindQuantity,
        bytes32 blindKey
    ) public payable returns (uint256 limitingQuantity) {
        require(manufacturerID <= num_manufacturer, "Invalid ID");
        require(supplierID <= num_supplier, "Invalid ID");
        require(
            msg.sender == manufacturers[manufacturerID].wallet,
            "Incorrect ID"
        );
        if (suppliers[supplierID].partType == PartType.WHEEL) {
            require(
                manufacturers[manufacturerID].wheelSupplier == supplierID,
                "Incorrect supplier"
            );
        } else {
            require(
                manufacturers[manufacturerID].bodySupplier == supplierID,
                "Incorrect supplier"
            );
        }
        require(
            suppliers[supplierID].bidsPlaced <=
                suppliers[supplierID].maxBidders,
            "Max bids recieved"
        );
        uint256 limiting;
        if (suppliers[supplierID].partType == PartType.BODY) {
            uint256 bodySupplier = manufacturers[manufacturerID].bodySupplier;
            limiting =
                suppliers[bodySupplier].quantityAvailable +
                manufacturers[manufacturerID].bodyQuant;
        } else {
            uint256 wheelSupplier = manufacturers[manufacturerID].wheelSupplier;
            limiting =
                suppliers[wheelSupplier].quantityAvailable +
                manufacturers[manufacturerID].wheelQuant;
        }
        bidsTillNow[suppliers[supplierID].wallet].push(
            Bid(
                0,
                0,
                0,
                blindPrice,
                blindQuantity,
                blindKey,
                limiting,
                manufacturerID,
                supplierID,
                msg.value,
                false,
                payable(msg.sender)
            )
        );
        suppliers[supplierID].bidsPlaced += 1;
        emit ManufacturerBids(
            manufacturerID,
            supplierID,
            blindPrice,
            blindQuantity,
            blindKey
        );
        return limiting;
    }

    function manufacturerRevealsBid(
        uint256 manufacturerID,
        uint256 supplierID,
        uint256 actualPrice,
        uint256 actualQuantity,
        uint256 actualKey
    ) public returns (bool) {
        require(manufacturerID <= num_manufacturer, "Invalid ID");
        require(supplierID <= num_supplier, "Invalid ID");
        require(
            suppliers[supplierID].currentState == AuctionState.REVEALING,
            "Reveal phase not going on"
        );
        require(
            manufacturers[manufacturerID].wallet == msg.sender,
            "Invalid ID"
        );
        for (
            uint256 i = 0;
            i < bidsTillNow[suppliers[supplierID].wallet].length;
            i++
        ) {
            if (
                bidsTillNow[suppliers[supplierID].wallet][i].buyerID !=
                manufacturerID
            ) continue;
            Bid memory bid = bidsTillNow[suppliers[supplierID].wallet][i];
            require(bid.correctReveal == false, "Bid already revealed");
            require(
                keccak256(abi.encodePacked(actualKey)) == bid.blindKey,
                "Incorrect key -- keeping your money"
            );
            require(
                keccak256(abi.encodePacked(actualKey + actualPrice)) ==
                    bid.blindPrice,
                "Incorrect price -- keeping your money"
            );
            require(
                keccak256(abi.encodePacked(actualKey + actualQuantity)) ==
                    bid.blindQuantity,
                "Incorrect quantity -- keeping your money"
            );
            uint256 effectivePrice = actualPrice * actualQuantity;
            require(
                effectivePrice < bid.moneySent,
                "Insufficient funds sent -- keeping your money"
            );
            bidsTillNow[suppliers[supplierID].wallet][i].correctReveal = true;
            bidsTillNow[suppliers[supplierID].wallet][i]
                .actualPrice = actualPrice;
            bidsTillNow[suppliers[supplierID].wallet][i]
                .actualQuantity = actualQuantity;
            bidsTillNow[suppliers[supplierID].wallet][i].actualKey = actualKey;
            suppliers[supplierID].bidsRevealed += 1;
            emit ManufacturerReveal(
                manufacturerID,
                supplierID,
                actualPrice,
                actualQuantity,
                actualKey
            );
            return true;
        }
        return false;
    }

    function customerBuysCar(
        uint256 customerID,
        uint256 manufacturerID,
        uint256 priceOfferedPerCar,
        uint256 quantityRequested
    ) public payable returns (uint256) {
        require(customerID <= num_customer, "Invalid customer");
        require(manufacturerID <= num_manufacturer, "Invalid customer");
        require(
            priceOfferedPerCar >= manufacturers[manufacturerID].carPrice,
            "Cost is higher"
        );
        require(
            msg.value >= priceOfferedPerCar * quantityRequested,
            "Insufficient funds sent"
        );
        require(
            msg.sender == payable(customers[customerID].wallet),
            "Incorrect ID"
        );
        uint256 selling = minimum(
            quantityRequested,
            manufacturers[manufacturerID].carsAvailable
        );
        for (uint256 i = 0; i < selling; i++) {
            num_cars++;
            cars[num_cars] = Car(
                num_cars,
                customerID,
                manufacturerID,
                manufacturers[manufacturerID].wheelSupplier,
                manufacturers[manufacturerID].bodySupplier
            );
            emit CarSold(num_cars, manufacturerID, customerID);
        }
        manufacturers[manufacturerID].carsAvailable -= selling;
        require(
            payable(manufacturers[manufacturerID].wallet).send(
                selling * priceOfferedPerCar
            ),
            "Transaction failed"
        );
        return selling;
    }

    function verifyCar(uint256 customerID, uint256 carID)
        public
        view
        returns (
            uint256 id,
            uint256 manufacturerID,
            uint256 wheelSupplier,
            uint256 bodySupplier
        )
    {
        require(customerID <= num_customer, "Invalid car");
        require(customers[customerID].wallet == msg.sender, "Incorrect ID");
        require(carID <= num_cars, "Invalid car");
        require(cars[carID].customerID == customerID, "Not your car!");
        return (
            carID,
            cars[carID].manufacturerID,
            cars[carID].wheelSupID,
            cars[carID].bodySupID
        );
    }

    function addSupplier(
        uint256 partType,
        uint256 quantityAvailable,
        address payable addr,
        uint256 auctionBidders
    ) public payable returns (uint256 tag) {
        require(partType <= 1, "Invalid part type!");
        require(msg.sender == addr, "Invalid sign up");
        num_supplier++;
        PartType here = PartType.BODY;
        if (partType == 1) here = PartType.WHEEL;
        suppliers[num_supplier] = Supplier(
            num_supplier,
            here,
            quantityAvailable,
            AuctionState.NOT_RUNNING,
            addr,
            auctionBidders,
            0,
            0
        );
        return num_supplier;
    }

    function addManufacturer(
        address payable addr,
        uint256 wheelSupplier,
        uint256 bodySupplier,
        uint256 askingPrice
    ) public returns (uint256 tag) {
        require(
            wheelSupplier >= 1 && wheelSupplier <= num_supplier,
            "Invalid supplier!"
        );
        require(
            bodySupplier >= 1 && bodySupplier <= num_supplier,
            "Invalid supplier!"
        );
        require(
            suppliers[bodySupplier].partType == PartType.BODY,
            "Supplier doesn't suppl body"
        );
        require(
            suppliers[wheelSupplier].partType == PartType.WHEEL,
            "Supplier doesn't suppl wheels"
        );
        require(msg.sender == addr, "Invalid sign up");
        num_manufacturer++;
        manufacturers[num_manufacturer] = Manufacturer(
            num_manufacturer,
            wheelSupplier,
            0,
            bodySupplier,
            0,
            0,
            askingPrice,
            addr
        );
        return num_manufacturer;
    }

    function addCustomer(address payable addr) public returns (uint256 tag) {
        require(msg.sender == addr, "Invalid sign up");
        num_customer++;
        customers[num_customer] = Customer(num_customer, addr);
        return num_customer;
    }

    function getSuppliers() public view returns (uint256) {
        return num_supplier;
    }

    function getManufacturers() public view returns (uint256) {
        return num_manufacturer;
    }

    function getCustomers() public view returns (uint256) {
        return num_customer;
    }

    function getCars() public view returns (uint256) {
        return num_cars;
    }

    function getManufacturerQuantities(uint256 tag)
        public
        view
        returns (
            uint256 quantityWheel,
            uint256 quantityBody,
            uint256 quantityCar
        )
    {
        require(tag <= num_manufacturer);
        return (
            manufacturers[tag].wheelQuant,
            manufacturers[tag].bodyQuant,
            manufacturers[tag].carsAvailable
        );
    }
}
