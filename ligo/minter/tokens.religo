#if !TOKENS
#define TOKENS

#include "../fa2/fa.2.interface.religo"
#include "ethereum.religo"
#include "interface.religo"


let token_id = (token_id: eth_address, tokens: map(eth_address, token_address)): token_address => {
  switch(Map.find_opt(token_id, tokens)) {
    | Some(n) => n
    | None => (failwith ("Unknown token."): token_address)
  };
};

let token_tokens_entry_point = (token_contract_address:address): contract(token_manager) => {
  switch(Tezos.get_entrypoint_opt("%tokens", token_contract_address): option(contract(token_manager))) {
    | Some(n) => n
    | None => (failwith ("Token contract is not compatible."):contract(token_manager))
  };
};

let token_admin_entry_point = (token_contract_address:address): contract(token_admin) => {
  switch(Tezos.get_entrypoint_opt("%admin", token_contract_address): option(contract(token_admin))) {
    | Some(n) => n
    | None => (failwith ("Token contract is not compatible."):contract(token_admin))
  };
};

#endif