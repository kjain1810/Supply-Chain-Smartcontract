# Code Explanation

## Public API
### User control operations
- addSupplier: Adds a supplier
- addManufacturer: Adds a manufacturer
- addCustomer: Adds a customer

### Supplier side operations 
- supplierStartAuction: Allows supplier to start their auction
- supplierEndAuction: Allows supplier to end bidding phase of auction
- supplierEndReveal: Allows supplier to end reveal phase and allocate
- supplierAddQuantity: Allows supplier to add inventory

### Manufacturer side operations
- manufacturerPlacesBid: Allows manufacturer to place bid to supplier
- manufactuerRevealBid: Allows manufacturer to reveal their bid
- manufacturerSupplyCars: Allows manufacturer to supply cars

### Customer side operations
- customerPurchase: Allows customers to place a purchase
- verifyproduct: Allows customer to verify their purchases

## Goals
### Secret bidding
- All bids are placed using a commit reveal mechanism
- The price and quantity is sent after hashing 