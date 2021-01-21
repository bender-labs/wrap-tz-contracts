#if !TOKENS
#define TOKENS

#include "../fa2/fa.2.interface.religo"
#include "ethereum.religo"
#include "interface.religo"


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

let token_admin_entry_point = (storage: assets_storage): contract(token_admin) => {
  switch(Tezos.get_entrypoint_opt("%admin", storage.fa2_contract): option(contract(token_admin))) {
    | Some(n) => n
    | None => (failwith ("Token contract is not compatible."):contract(token_admin))
  };
};

#endif