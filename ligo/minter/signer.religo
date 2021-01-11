#include "tokens.religo"
#include "ethereum.religo"

type mint_parameters = {
  token_id: eth_address,
  tx_id: eth_tx_id,
  owner: address,
  amount: nat
};

type add_token_parameters = {
  token_id: fa2_token_id,
  eth_contract: eth_address,
  eth_symbol: string,
  symbol: string,
  name: string,
  decimals: nat
};

type signer_entrypoints = 
  Mint_token(mint_parameters)
  | Add_token(add_token_parameters);


let check_already_minted = (tx_id: eth_tx_id, mints:mints): unit => {
  let former_mint = Map.find_opt(tx_id, mints);
  switch(former_mint) {
    | Some(n)=> failwith ("TX_ALREADY_MINTED")
    | None => unit
  }
};

let compute_fees = (value: nat, bps:nat):(nat, nat) => {
  let fees:nat = value * bps / 10_000n;
  let amount_to_mint:nat = switch(Michelson.is_nat(value - fees)){
    | Some(n) => n
    | None => (failwith("BAD_FEES"):nat)
  };
  (amount_to_mint, fees);
};

let mint = ((s, p):(assets_storage, mint_parameters)) : (list(operation), assets_storage) => {
  check_already_minted(p.tx_id, s.mints);
  let (amount_to_mint, fees) : (nat, nat) = compute_fees(p.amount, s.fees_ratio);
  let token_id = token_id(p.token_id, s.tokens);
  let mintEntryPoint = token_tokens_entry_point(s);

  let userMint:mint_burn_tx = {owner:p.owner, token_id: token_id, amount:amount_to_mint};
  let operations:mint_burn_tokens_param = if(fees > 0n) {
    [userMint,{owner:s.fees_contract, token_id: token_id, amount:fees}];
  } else {
    [userMint];
  };
  let mints = Map.add((p.tx_id), unit , s.mints);
  (([Tezos.transaction(Mint_tokens(operations), 0mutez, mintEntryPoint)], {...s, mints:mints}));
};

let add_token = ((s, p): (assets_storage, add_token_parameters)) : (list(operation), assets_storage) => {
  let manager_ep = token_tokens_entry_point(s);
  let meta : token_metadata = {
    token_id :  p.token_id,
    symbol : p.symbol,
    name : p.name,
    decimals : p.decimals,
    extras : Map.literal([("eth_symbol", p.eth_symbol)])
  };
  let op = Tezos.transaction(Create_token(meta), 0mutez, manager_ep);
  let updated_tokens = Map.update(p.eth_contract, Some(p.token_id), s.tokens);
  (([op]:list(operation)), {...s, tokens:updated_tokens});
};

let signer_main = ((p, s):(signer_entrypoints, assets_storage)): (list(operation), assets_storage) => {
    switch(p) {
        | Mint_token(n) => mint(s, n);
        | Add_token(p) => add_token(s, p);
    };
}