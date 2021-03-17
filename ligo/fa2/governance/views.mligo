#include "fa2.mligo"

type get_balance_parameter = {
    owner: address;
    token_id: nat;
}

type get_balance_return = nat


let get_balance_view ((p,s):(get_balance_parameter * storage)) : get_balance_return = 
    if(not Big_map.mem p.token_id s.assets.total_supply) then
        (failwith(fa2_token_undefined):get_balance_return)
    else
        let ledger = s.assets.ledger in
        let key = (p.owner, p.token_id) in
        let res = Big_map.find_opt key ledger in
        match res with 
        | None -> 0n
        | Some v -> v

let get_balance_main ((p,s):(get_balance_parameter * storage)) : (operation list * storage) = (([]:operation list), s)

type total_supply_return = nat

let total_supply_view  ((token_id,s):(nat * storage)): total_supply_return =
    let supply = s.assets.total_supply in
    let total = Big_map.find_opt token_id supply in
    match total with
    | None -> (failwith(fa2_token_undefined):nat)
    | Some v -> v
    

let total_supply_main  ((token_id,s):(nat * storage)):(operation list * storage) = (([]:operation list), s)

type tokens_distributed_return = nat

let tokens_distributed_view  (s:storage): tokens_distributed_return =
    s.bender.distributed
    

let tokens_distributed_main  ((u,s):(unit * storage)):(operation list * storage) = (([]:operation list), s)

type is_operator_parameter = {
    owner: address;
    operator: address;
    token_id: token_id;
}

type is_operator_return = bool

let is_operator_view ((p, s):(is_operator_parameter * storage)) : is_operator_return =
    let key: operator = { owner = p.owner; operator = p.operator} in
    Big_map.mem key s.assets.operators

let is_operator_main ((p, s):(is_operator_parameter * storage)):(operation list * storage) = (([]:operation list), s)

type token_metadata_return = token_metadata

let token_metadata_view ((token_id,s):(nat * storage)) : token_metadata_return =
    if token_id = unfrozen_token_id || token_id = frozen_token_id
    then 
        let r = Big_map.find_opt token_id s.assets.token_metadata in
        match r with 
        | None -> (failwith(fa2_token_undefined):token_metadata)
        | Some v -> v
    else 
        let r = Big_map.find_opt token_id s.assets.total_supply in
        match r with 
        | None -> (failwith(fa2_token_undefined):token_metadata)
        | Some v -> 
            {token_id=token_id; token_info=s.assets.proposal_metadata}


let token_metadata_main ((token_id,s):(nat * storage)):(operation list * storage) = (([]: operation list),s)