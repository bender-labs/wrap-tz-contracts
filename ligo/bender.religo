#include "fa.2.interface.religo"

type storage = {
  administrator: address,
  feesContract : address,
  feesRatio: nat,
  tokens : map(string, address),
  mints : big_map(string, unit)
};

type mintParameters = {
  tokenId: string,
  mainChainTxId: string,
  owner: address,
  amount: nat
};

type ethAddress = string;

type burnParameters = {
  tokenId: string,
  amount: nat,
  destinationAddress: ethAddress
};

type action = 
  Mint(mintParameters)
  | Burn(burnParameters)
  | SetAdministrator(address)
  | SetFeesRatio(nat)
  | AddToken((string,address))
  | RemoveToken(string)
  | ChangeTokensAdministrator
  ;

type return = (list(operation), storage);

let check_is_allowed = (administrator:address) : unit => {
  if(administrator != Tezos.sender) {
    failwith("Sender is not administrator.");
  };
};

let check_already_minted = (txId: string, mints:big_map(string, unit)): unit => {
  let formerMint = Map.find_opt(txId, mints);
  switch(formerMint) {
    | Some(n)=> failwith ("Tx already minted.")
    | None => unit
  }
};

let token_contract = (tokenId: string, tokens: map(string, address)): address => {
  switch(Map.find_opt(tokenId, tokens)) {
    | Some(n) => n
    | None => (failwith ("Unknown token."): address)
  };
};

let token_tokens_entry_point = (tokenId:string, tokens:map(string, address)): contract(token_manager) => {
  switch(Tezos.get_entrypoint_opt("%tokens", token_contract(tokenId, tokens)): option(contract(token_manager))) {
    | Some(n) => n
    | None => (failwith ("Token contract is not compatible."):contract(token_manager))
  };
};

let compute_fees = (value: nat, bps:nat):(nat, nat) => {
  let fees:nat = value * bps / 10_000n;
  let amountToMint:nat = switch(Michelson.is_nat(value - fees)){
    | Some(n) => n
    | None => (failwith("Bad fees computation."):nat)
  };
  (amountToMint, fees);
};

let mint = ((s, p):(storage, mintParameters)):return => {
  check_is_allowed(s.administrator);
  check_already_minted(p.mainChainTxId, s.mints);
  let (amountToMint, fees) : (nat, nat) = compute_fees(p.amount, s.feesRatio);
  let mintEntryPoint = token_tokens_entry_point(p.tokenId, s.tokens);

  let userMint:mint_burn_tx = {owner:p.owner, amount:amountToMint};
  let operations:mint_burn_tokens_param = if(fees > 0n) {
    [userMint,{owner:s.feesContract, amount:fees}];
  } else {
    [userMint];
  };
  let mints = Map.add((p.mainChainTxId:string), unit , s.mints);
  (([Tezos.transaction(Mint_tokens(operations), 0mutez, mintEntryPoint)], {...s, mints:mints}));
};

let burn = ((s, p) : (storage, burnParameters)):return => {
  // todo: check ethAddr
  let burnEntryPoint = token_tokens_entry_point(p.tokenId, s.tokens);
  (([Tezos.transaction(Burn_tokens([{owner:Tezos.source, amount:p.amount}]), 0mutez, burnEntryPoint)]), s);
};

let setAdministrator = ((s, newAdministrator):(storage, address)):return =>  {
  check_is_allowed(s.administrator);
  (([]:list(operation)), {...s, administrator:newAdministrator});
};

let setFeesRatio = ((s, value) : (storage, nat)): return => {
  (([]:list(operation)), {...s, feesRatio:value});
};

// todo : check contract type
let addToken = ((s, p): (storage, (string, address))) : return => {
  check_is_allowed(s.administrator);
  let (id, contractAddress) = p;
  let updatedTokens = Map.update((id:string), Some(contractAddress), s.tokens);
  (([]:list(operation)), {...s, tokens:updatedTokens});
};

let removeToken = ((s, p): (storage, string)) : return => {
  let updatedTokens = Map.remove(p, s.tokens);
  (([]:list(operation)), {...s, tokens:updatedTokens});
};

// todo: refuser le dépôt de fond
let main = ((p, s):(action, storage)):return => {
  switch(p) {
    | Mint(n) => mint(s, n)
    | Burn(n) => burn(s, n)
    | SetAdministrator(n)=>setAdministrator(s, n)
    | SetFeesRatio(n) => setFeesRatio(s, n)
    | AddToken(n) => addToken(s, n)
    | RemoveToken(n) => removeToken(s, n)
    | ChangeTokensAdministrator => (failwith ("Not implemented"):return)
    ;
  };
};