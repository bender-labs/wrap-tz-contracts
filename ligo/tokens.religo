#if !TOKENS
#define TOKENS

#include "fa.2.interface.religo"
#include "ethereum.religo"

type bps = nat

type assets_storage = {
  fa2_contract: address,
  fees_contract : address,
  fees_ratio: bps,
  tokens : map(eth_address, fa2_token_id),
  mints : big_map(eth_tx_id, unit)
};

let token_id = (token_id: eth_address, tokens: map(eth_address, fa2_token_id)): fa2_token_id => {
  switch(Map.find_opt(token_id, tokens)) {
    | Some(n) => n
    | None => (failwith ("Unknown token."): fa2_token_id)
  };
};

let token_tokens_entry_point = (storage: assets_storage): contract(token_manager) => {
  switch(Tezos.get_entrypoint_opt("%tokens", storage.fa2_contract): option(contract(token_manager))) {
    | Some(n) => n
    | None => (failwith ("Token contract is not compatible."):contract(token_manager))
  };
};

#endif