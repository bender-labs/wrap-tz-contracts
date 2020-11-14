#include "tokens.religo"

type eth_tx_id = string;

type mint_parameters = {
  token_id: string,
  tx_id: eth_tx_id,
  owner: address,
  amount: nat
};

type signer_entrypoints = Mint_token(mint_parameters);


let check_already_minted = (txId: string, mints:big_map(string, unit)): unit => {
  let former_mint = Map.find_opt(txId, mints);
  switch(former_mint) {
    | Some(n)=> failwith ("Tx already minted.")
    | None => unit
  }
};

let compute_fees = (value: nat, bps:nat):(nat, nat) => {
  let fees:nat = value * bps / 10_000n;
  let amount_to_mint:nat = switch(Michelson.is_nat(value - fees)){
    | Some(n) => n
    | None => (failwith("Bad fees computation."):nat)
  };
  (amount_to_mint, fees);
};

let mint = ((s, p):(assets_storage, mint_parameters)) : (list(operation), assets_storage) => {
  check_already_minted(p.tx_id, s.mints);
  let (amount_to_mint, fees) : (nat, nat) = compute_fees(p.amount, s.fees_ratio);
  let mintEntryPoint = token_tokens_entry_point(p.token_id, s.tokens);

  let userMint:mint_burn_tx = {owner:p.owner, amount:amount_to_mint};
  let operations:mint_burn_tokens_param = if(fees > 0n) {
    [userMint,{owner:s.fees_contract, amount:fees}];
  } else {
    [userMint];
  };
  let mints = Map.add((p.tx_id:string), unit , s.mints);
  (([Tezos.transaction(Mint_tokens(operations), 0mutez, mintEntryPoint)], {...s, mints:mints}));
};

let signer_main = ((p, s):(signer_entrypoints, assets_storage)): (list(operation), assets_storage) => {
    switch(p) {
        | Mint_token(n) => mint(s, n);
    };
}