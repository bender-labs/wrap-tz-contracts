#include "tokens.religo"
#include "ethereum.religo"

type mint_parameters = {
  token_id: eth_address,
  event_id: eth_event_id,
  owner: address,
  amount: nat
};

type add_token_parameters = {
  eth_contract: eth_address,
  token_address: token_address
};

type signer_entrypoints = 
  Mint_token(mint_parameters)
  | Add_token(add_token_parameters);


let check_already_minted = (tx_id: eth_event_id, mints:mints): unit => {
  let former_mint = Map.find_opt(tx_id, mints);
  switch(former_mint) {
    | Some(n)=> failwith ("TX_ALREADY_MINTED")
    | None => unit
  }
};

let compute_fees = (value: nat, bps:nat):(nat, nat) => {
  let fees:nat = value * bps / 10_000n;
  let amount_to_mint:nat = switch(Michelson.is_nat(value - fees)) {
    | Some(n) => n
    | None => (failwith("BAD_FEES"):nat)
  };
  (amount_to_mint, fees);
};

let mint = ((p,f, s):(mint_parameters, governance_storage, assets_storage)) : (list(operation), assets_storage) => {
  check_already_minted(p.event_id, s.mints);
  let (amount_to_mint, fees) : (nat, nat) = compute_fees(p.amount, f.wrapping_fees);
  let (token_address, token_id) : token_address = token_id(p.token_id, s.tokens);
  let mintEntryPoint = token_tokens_entry_point(token_address);

  let userMint:mint_burn_tx = {owner:p.owner, token_id: token_id, amount:amount_to_mint};
  let operations:mint_burn_tokens_param = if(fees > 0n) {
    [userMint,{owner: f.fees_contract, token_id: token_id, amount:fees}];
  } else {
    [userMint];
  };
  let mints = Map.add((p.event_id), unit , s.mints);
  (([Tezos.transaction(Mint_tokens(operations), 0mutez, mintEntryPoint)], {...s, mints:mints}));
};

let add_token = ((p, s): (add_token_parameters, assets_storage)) : (list(operation), assets_storage) => {
  // checks contract compat
  let token_ep = token_tokens_entry_point(p.token_address[0]);
  let admin_ep = token_admin_entry_point(p.token_address[0]);
  
  let updated_tokens = Map.update(p.eth_contract, Some(p.token_address), s.tokens);
  (([]:list(operation)), {...s, tokens:updated_tokens});
};

let signer_main = ((p, g, s):(signer_entrypoints, governance_storage, assets_storage)): (list(operation), assets_storage) => {
    switch(p) {
        | Mint_token(p) => mint(p, g, s);
        | Add_token(p) => add_token(p, s);
    };
}