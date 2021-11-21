// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;

  uint public skuCount;

  Item[] items;

  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
    }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  
  /* 
   * Events
   */
  event LogForSale(uint sku);
  
  event LogSold(uint sku);
  
  event LogShipped(uint sku);

  event LogReceived(uint sku);

  event LogAddress(string item);

  event LogItem(Item newItem);

  /* 
   * Modifiers
   */

  modifier isOwner {
    require(msg.sender == owner);
      _;
  }

  modifier verifySeller (uint _sku) { 
    require (msg.sender == items[_sku].seller); 
    _;
  }

  modifier verifyBuyer (uint _sku) { 
    require (msg.sender == items[_sku].buyer); 
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku) {
    require(items[_sku].state == State.ForSale);
    _;
  }
  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }
  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }
  modifier received(uint _sku){
    require(items[_sku].state == State.Received);
    _;
  }

  constructor() public payable {
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary?
    owner = msg.sender;
    skuCount = 0;
  }

  fallback () external payable { revert(); }

  receive () external payable { revert(); }

  function addItem(string memory _name, uint _price) public returns (bool) {
    Item memory newItem = Item({
     name: _name, 
     sku: skuCount, 
     price: _price, 
     state: State.ForSale, 
     seller: payable(msg.sender),
     buyer: payable(address(0))
    });
    
    items.push(newItem);

    skuCount = skuCount + 1;
    emit LogForSale(skuCount);

    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(msg.value){
    items[sku].seller.transfer(items[sku].price);
    items[sku].buyer = payable(msg.sender);
    items[sku].state = State.Sold;
    emit LogSold(sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint sku) public sold(sku) verifySeller(sku) {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint sku) public shipped(sku) verifyBuyer(sku){
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  function fetchItem(uint _sku) public view
  returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) 
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
