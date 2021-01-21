#include "fa.2.interface.religo"

type get_balance_parameter = {
    owner: address,
    token_id: nat
};

type get_balance_return = nat;

let token_undefined = "FA2_TOKEN_UNDEFINED"

let get_balance_view = (p:get_balance_parameter,s:fa2_storage) : get_balance_return => {
    if(! Big_map.mem(p.token_id, s.assets.token_metadata)) {
        (failwith(token_undefined):get_balance_return);
    } else {
        let ledger = s.assets.ledger;
        let key = (p.owner, p.token_id);
        let res = Big_map.find_opt(key, ledger);
        switch(res) {
            | None => 0n;
            | Some v => v;
        };
    }
    
};

let get_balance_main = ((p,s):(get_balance_parameter,fa2_storage)) : (list(operation), fa2_storage) => ([]:list(operation), s);


let total_supply_view = (token_id:nat, s:fa2_storage): nat => {
    let supply = s.assets.token_total_supply;
    let total = Big_map.find_opt(token_id, supply);
    switch(total) {
        | None => (failwith(token_undefined):nat);
        | Some v => v;
    };
}

let total_supply_main = (token_id:nat, s:fa2_storage):(list(operation), fa2_storage) => ([]:list(operation), s);

type is_operator_parameter = {
    owner: address,
    operator: address,
    token_id: fa2_token_id
};

let is_operator_view = (p:is_operator_parameter, s: fa2_storage) : bool => {
  let key = (p.owner, (p.operator, p.token_id));
  Big_map.mem(key, s.assets.operators);
};

let is_operator_main = (p:is_operator_parameter, s:fa2_storage):(list(operation), fa2_storage) => ([]:list(operation), s);

let token_metadata_view = (token_id:nat, s:fa2_storage):token_metadata => {
    let r = Big_map.find_opt(token_id, s.assets.token_metadata);
    switch(r) {
        | None => (failwith(token_undefined):token_metadata);
        | Some v => v;
    };
};

let token_metadata_main = (token_id:nat, s:fa2_storage):(list(operation), fa2_storage) => ([]:list(operation),s);