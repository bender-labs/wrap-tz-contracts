#include "tokens.religo"

type governance_entrypoints = 
   Set_fees_ratio(nat)
  | Add_token((string,address))
  | Remove_token(string)
  ;

type innerStorage = int

let create_contract : (option(key_hash), tez, fa2_storage) => (operation, address)= 
    [%Michelson ({| { 
        UNPPAIIR ;
        CREATE_CONTRACT 
#include "../michelson/fa2.tz"
        ;
        PAIR  
    } |} : ((option(key_hash), tez, fa2_storage) => (operation, address) ))]

let set_fees_ratio = ((s, value) : (assets_storage, nat)): (list(operation), assets_storage) => {
  (([]:list(operation)), {...s, fees_ratio:value});
};

let add_token = ((s, p): (assets_storage, (string, address))) : (list(operation), assets_storage) => {
    let (id, contractAddress) = p;
    let storage: fa2_storage = {
        admin: {
            admin: Tezos.self_address,
            pending_admin: None: option(address),
            paused: false
        },
        assets:{
            ledger: Big_map.empty : fa2_ledger,
            operators: Big_map.empty : fa2_operator_storage ,
            token_metadata: Big_map.literal([(0n, Layout.convert_to_right_comb({
                token_id : 0n,
                symbol : id,
                name : id,
                decimals : 16n,
                extras : Map.empty : map(string, string)
                }))]),
            total_supply: 0n
        }
        
  };
  let (op, contract_addr) = create_contract(None : option(key_hash), 0tez, storage);
  let updated_tokens = Map.update((id:string), Some(contract_addr), s.tokens);
  (([op]:list(operation)), {...s, tokens:updated_tokens});
};

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