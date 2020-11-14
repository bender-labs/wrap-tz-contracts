#include "fa.2.interface.religo"
#include "admin.religo"
#include "governance.religo"

type ethAddress = string;

type ethTxId = string;

type storage = {
  admin: admin_storage,
  tokens: tokens_storage
};

type mintParameters = {
  tokenId: string,
  mainChainTxId: ethTxId,
  owner: address,
  amount: nat
};

type burnParameters = {
  tokenId: string,
  amount: nat,
  destinationAddress: ethAddress
};

type entry_points = 
  Mint(mintParameters)
  | Burn(burnParameters)
  | Admin(admin_entrypoints)
  | Governance(governance_entrypoints)
  | ChangeTokensAdministrator
  ;

type return = (list(operation), storage);

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

let mint = ((s, p):(tokens_storage, mintParameters)) : (list(operation), tokens_storage) => {
  check_already_minted(p.mainChainTxId, s.mints);
  let (amountToMint, fees) : (nat, nat) = compute_fees(p.amount, s.fees_ratio);
  let mintEntryPoint = token_tokens_entry_point(p.tokenId, s.tokens);

  let userMint:mint_burn_tx = {owner:p.owner, amount:amountToMint};
  let operations:mint_burn_tokens_param = if(fees > 0n) {
    [userMint,{owner:s.fees_contract, amount:fees}];
  } else {
    [userMint];
  };
  let mints = Map.add((p.mainChainTxId:string), unit , s.mints);
  (([Tezos.transaction(Mint_tokens(operations), 0mutez, mintEntryPoint)], {...s, mints:mints}));
};

let burn = ((s, p) : (tokens_storage, burnParameters)):(list(operation), tokens_storage) => {
  // todo: check ethAddr
  let burnEntryPoint = token_tokens_entry_point(p.tokenId, s.tokens);
  (([Tezos.transaction(Burn_tokens([{owner:Tezos.source, amount:p.amount}]), 0mutez, burnEntryPoint)]), s);
};

// todo: refuser le dépôt de fond
let main = ((p, s):(entry_points, storage)):return => {
  switch(p) {
    | Mint(n) => {
      fail_if_not_signer(s.admin);
      let (ops, new_storage) = mint(s.tokens, n);
      (ops, {...s, tokens:new_storage});
    }
    | Burn(n) => {
      let (ops, new_storage) = burn(s.tokens, n);
      (ops, {...s, tokens:new_storage});
    }
    | Admin(n)=> {
      fail_if_not_admin(s.admin);
      let (ops, new_storage) = admin_main(n, s.admin);
      (ops:list(operation), {...s, admin:new_storage});
    }
    | Governance(n) => {
      fail_if_not_governance(s.admin);
      let (ops, new_storage) = governance_main(n, s.tokens);
      (ops, {...s, tokens: new_storage});
    }
    | ChangeTokensAdministrator => (failwith ("Not implemented"):return)
    ;
  };
};