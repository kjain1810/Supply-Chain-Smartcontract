To test in truffle

truffle compile

truffle develop
(in console)

truffle deploy

let instance = await Marketplace.deployed()

instance.function(args)


## Rough documentation for us right now
### Functions
- supplierStartAuction : suppliers can start their auctions
- supplierEndAuction : suppliers can end their auctions
- supplierEndReveal : Reveal phase of the bidding is finished and allocation happens now (implements resource optimal allocation)
- transferMoney : transfer money
- manufacturerPlacesBid : manufacturer places bid to supplier from this if bidding phase is on
- manufactuerRevealBid : manufacturer reveals their bid to supplier from this if reveal phase is on
- addSupplier, addManufacturer, addCustomer : adds the actors
- supplierAddQuantity : adds quantity for the supplier
- Update_Manufacturer_Quantities : adds quantity for the manufacturer

### Events
- StartSupplierAuction : supplier starts auction
- EndSupplierAuction : supplier ends auction
- AllocateFromSupplier : supplier sends goods to manufacturer
- ManufacturerBids : manufacturer places a bid to the supplier
- ManufacturerReveal : manufacturer reveals their bid to the supplier

### Note points
- Only 1 bid per auction is supported. Incase of multiple bids, first bid is considered
- keccak256 encryption for hiding the bids
- no penalties right now for incorrect reveals, just ignore from auction
- 