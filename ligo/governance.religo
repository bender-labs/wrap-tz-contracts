#include "tokens.religo"
#include "ethereum.religo"

type add_token_parameters = {
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
  | Remove_token(string)
  ;

// todo : adds a minimum check ?
let set_fees_ratio = ((s, value) : (assets_storage, nat)): (list(operation), assets_storage) => {
  (([]:list(operation)), {...s, fees_ratio:value});
};

let create_contract : (option(key_hash), tez, fa2_storage) => (operation, address)= 
    [%Michelson ({| { 
        UNPPAIIR ;
        CREATE_CONTRACT 
#include "../michelson/fa2.tz"
        ;
        PAIR  
    } |} : ((option(key_hash), tez, fa2_storage) => (operation, address) ))]

let add_token = ((s, p): (assets_storage, add_token_parameters)) : (list(operation), assets_storage) => {
    let storage: fa2_storage = {
        admin: {
            admin: Tezos.self_address,
            pending_admin: None: option(address),
            paused: false
        },
        assets:{
            ledger: Big_map.empty : fa2_ledger,
            operators: Big_map.empty : fa2_operator_storage,
            token_metadata: Big_map.literal([(0n, Layout.convert_to_right_comb({
                token_id : 0n,
                symbol : p.symbol,
                name : p.name,
                decimals : p.decimals,
                extras : Map.literal([
                  ("eth_symbol", p.eth_symbol),
                  ("eth_contract", p.eth_contract)
                  ])
                }))]),
            total_supply: 0n
        }
        
  };
  let (op, contract_addr) = create_contract(None : option(key_hash), 0tez, storage);
  let updated_tokens = Map.update(p.eth_contract, Some(contract_addr), s.tokens);
  (([op]:list(operation)), {...s, tokens:updated_tokens});
};

// todo : pause maybe ?
let remove_token = ((s, p): (assets_storage, string)) : (list(operation), assets_storage) => {
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