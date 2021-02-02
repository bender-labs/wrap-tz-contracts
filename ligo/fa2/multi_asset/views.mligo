#include "fa2_multi_asset.mligo"

type get_balance_parameter = {
    owner: address;
    token_id: nat;
}

type get_balance_return = nat

let token_undefined = "FA2_TOKEN_UNDEFINED"

let get_balance_view ((p,s):(get_balance_parameter * multi_asset_storage)) : get_balance_return = 
    if(not Big_map.mem p.token_id s.assets.token_metadata) then
        (failwith(token_undefined):get_balance_return)
    else
        let ledger = s.assets.ledger in
        let key = (p.owner, p.token_id) in
        let res = Big_map.find_opt key ledger in
        match res with 
        | None -> 0n
        | Some v -> v

let get_balance_main ((p,s):(get_balance_parameter * multi_asset_storage)) : (operation list * multi_asset_storage) = (([]:operation list), s)


let total_supply_view  ((token_id,s):(nat * multi_asset_storage)): nat = 
    let supply = s.assets.token_total_supply in
    let total = Big_map.find_opt token_id supply in
    match total with
    | None -> (failwith(token_undefined):nat)
    | Some v -> v
    

let total_supply_main  ((token_id,s):(nat * multi_asset_storage)):(operation list * multi_asset_storage) = (([]:operation list), s)

type is_operator_parameter = {
    owner: address;
    operator: address;
    token_id: token_id;
}

let is_operator_view ((p, s):(is_operator_parameter * multi_asset_storage)) : bool = 
  let key = (p.owner, (p.operator, p.token_id)) in
  Big_map.mem key s.assets.operators

let is_operator_main ((p, s):(is_operator_parameter * multi_asset_storage)):(operation list * multi_asset_storage) = (([]:operation list), s)

let token_metadata_view ((token_id,s):(nat * multi_asset_storage)) : token_metadata =
    let r = Big_map.find_opt token_id s.assets.token_metadata in
    match r with 
    | None -> (failwith(token_undefined):token_metadata)
    | Some v -> v


let token_metadata_main ((token_id,s):(nat * multi_asset_storage)):(operation list * multi_asset_storage) = (([]: operation list),s)