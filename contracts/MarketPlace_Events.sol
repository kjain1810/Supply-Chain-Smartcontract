pragma solidity >=0.8.16;

import {MarketPlace_Storage} from "./MP_Storage.sol";

contract MarketPlace_Events is MarketPlace_Storage {
    // @notice Triggered to start auction for a supplier
    // @param supplierID Tag ID of the supplier
    // @param startTime Blockheight when auction started
    event StartSupplierAuction(uint256 supplierID, uint256 startTime);

    // @notice Triggered to end auction for a supplier
    // @param supplierID Tag ID of the supplier
    // @param startTime Blockheight when auction ended
    event EndSupplierAuction(uint256 supplierID, uint256 endTime);

    // @notice Triggered to allocate resources from supplier to manufacturer
    // @param supplierID Tag ID of the supplier
    // @param manufacturerID Tag ID of the manufacturer
    // @param quantity Quantities ordered
    // @param price Price offered per unit
    event AllocateFromSupplier(
        uint256 supplierID,
        uint256 manufacturerID,
        uint256 quantity,
        uint256 price
    );

    // @notice Triggered to end auction for a manufacturer
    // @param manufacturerID Tag ID of the manufacturer
    // @param startTime Blockheight when auction ended
    event StartManufacturerAuction(uint256 manufacturerID, uint256 startTime);

    // @notice Triggered to end auction for a manufacturer
    // @param manufacturerID Tag ID of the manufacturer
    // @param startTime Blockheight when auction ended
    event EndManufacturerAuction(uint256 manufacturerID, uint256 endTime);

    // @notice Triggered when a customer requests to buy cars from a manufacturer
    // @param CustomerID Tag ID of the customer
    // @param ManufacturerID Tag ID of the manufacturer
    // @param Quantities Quantities requested
    // @param Price Price offered
    event CustomerRequest(
        uint256 CustomerID,
        uint256 ManufacturerID,
        uint256 Quantity,
        uint256 Price
    );

    // @notice Triggered to allocate cars from manufacturer to customer
    // @dev Limited to buying only 100 cars at once
    // @param manufacturerID Tag ID of the manufacturer
    // @param customerID Tag ID of the customer
    // @param quantity Quantities ordered
    // @param price Price offered per unit
    // @param carTag List of tags associated with the cars sold
    event AllocateFromManufacturer(
        uint256 manufacturerID,
        uint256 customerID,
        uint256 quantity,
        uint256 price,
        uint256[100] carTag
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
}
