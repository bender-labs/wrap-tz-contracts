#if !TOKENS
#define TOKENS

type bps = nat

type assets_storage = {
  fees_contract : address,
  fees_ratio: bps,
  tokens : map(string, address),
  mints : big_map(string, unit)
};

let token_contract = (token_id: string, tokens: map(string, address)): address => {
  switch(Map.find_opt(token_id, tokens)) {
    | Some(n) => n
    | None => (failwith ("Unknown token."): address)
  };
};

let token_tokens_entry_point = (token_id:string, tokens:map(string, address)): contract(token_manager) => {
  switch(Tezos.get_entrypoint_opt("%tokens", token_contract(token_id, tokens)): option(contract(token_manager))) {
    | Some(n) => n
    | None => (failwith ("Token contract is not compatible."):contract(token_manager))
  };
};

#endif