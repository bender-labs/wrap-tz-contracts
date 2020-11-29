#include "tokens.religo"
#include "ethereum.religo"
#include "fa.2.interface.religo"

type add_token_parameters = {
  token_id: fa2_token_id,
  eth_contract: eth_address,
  eth_symbol: string,
  symbol: string,
  name: string,
  decimals: nat
};

type bps = nat;

type governance_entrypoints = 
   Set_fees_ratio(bps)
  | Add_token(add_token_parameters)
  | Remove_token(eth_address)
  ;

// todo : adds a minimum check ?
let set_fees_ratio = ((s, value) : (assets_storage, nat)): (list(operation), assets_storage) => {
  (([]:list(operation)), {...s, fees_ratio:value});
};

let add_token = ((s, p): (assets_storage, add_token_parameters)) : (list(operation), assets_storage) => {

  let manager_ep = token_tokens_entry_point(s);
  let meta : token_metadata = {
    token_id :  p.token_id,
    symbol : p.symbol,
    name : p.name,
    decimals : p.decimals,
    extras : Map.literal([("eth_symbol", p.eth_symbol), ("eth_contract", p.eth_contract)])
  };
  let op = Tezos.transaction(Create_token(meta), 0mutez, manager_ep);
  let updated_tokens = Map.update(p.eth_contract, Some(p.token_id), s.tokens);
  (([op]:list(operation)), {...s, tokens:updated_tokens});
};

// todo : pause maybe ?
let remove_token = ((s, p): (assets_storage, eth_address)) : (list(operation), assets_storage) => {
  let updated_tokens = Map.remove(p, s.tokens);
  (([]:list(operation)), {...s, tokens:updated_tokens});
};

let governance_main = ((p, s):(governance_entrypoints, assets_storage)):(list(operation), assets_storage) => {
  switch(p) {
    | Set_fees_ratio(n) => set_fees_ratio(s, n)
    | Add_token(n) => add_token(s, n)
    | Remove_token(n) => remove_token(s, n)
    ;
  };
};