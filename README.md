To test in truffle

- Compile:
```bash
truffle compile
```
- Open console in development mode:
```bash
truffle develop
```

- Deploy
```bash
truffle deploy
```

- Start contract
```bash
let instance = await Marketplace.deployed()
```

- Call a function
```bash
instance.function(args)
```

- Get a mapping:
```bash
var balance = await instance.<mapping name>.call(account);
console.log(balance);
```
- 


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
- update_Manufacturer_Quantities : updates cars from quantities;
- manufacturerSuppliesCars : manufacturer sells cars 
- customerPurchase : customer places a order

### Events
- StartSupplierAuction : supplier starts auction
- EndSupplierAuction : supplier ends auction
- AllocateFromSupplier : supplier sends goods to manufacturer
- ManufacturerBids : manufacturer places a bid to the supplier
- ManufacturerReveal : manufacturer reveals their bid to the supplier
- CustomerRequest : customer requested for a purchase from manufacturer
- AllocateFromManufacturer : manufacturer supplied to customer

### Note points
- Only 1 bid per auction is supported. Incase of multiple bids, first bid is considered
- keccak256 encryption for hiding the bids
- no penalties right now for incorrect reveals, just ignore from auction
- 