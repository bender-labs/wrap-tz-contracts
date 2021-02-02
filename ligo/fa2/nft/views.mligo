#include "fa2_nft_asset.mligo"

type get_balance_parameter = {
    owner: address;
    token_id: nat;
}

type get_balance_return = nat

let token_undefined = "FA2_TOKEN_UNDEFINED"

let get_balance_view ((p,s):(get_balance_parameter * nft_asset_storage)) : get_balance_return = 
    let ledger = s.assets.ledger in
    if not Big_map.mem p.token_id ledger then
        (failwith(token_undefined):get_balance_return)
    else
        let res = Big_map.find_opt p.token_id ledger in
        match res with 
        | None -> 0n
        | Some v -> if v = p.owner then 1n else 0n

let get_balance_main ((p,s):(get_balance_parameter * nft_asset_storage)) : (operation list * nft_asset_storage) = (([]:operation list), s)


let total_supply_view  ((token_id,s):(nat * nft_asset_storage)): nat = 
    let ledger = s.assets.ledger in
    let total = Big_map.find_opt token_id ledger in
    match total with
    | None -> (failwith(token_undefined):nat)
    | Some v -> 1n
    

let total_supply_main  ((token_id,s):(nat * nft_asset_storage)):(operation list * nft_asset_storage) = (([]:operation list), s)

type is_operator_parameter = {
    owner: address;
    operator: address;
    token_id: token_id;
}

let is_operator_view ((p, s):(is_operator_parameter * nft_asset_storage)) : bool = 
  let key = (p.owner, (p.operator, p.token_id)) in
  Big_map.mem key s.assets.operators

let is_operator_main ((p, s):(is_operator_parameter * nft_asset_storage)):(operation list * nft_asset_storage) = (([]:operation list), s)

let token_metadata_view ((token_id,s):(nat * nft_asset_storage)) : token_metadata =
    let ledger = s.assets.ledger in
    if not Big_map.mem token_id ledger
    then (failwith(token_undefined):token_metadata)
    else
        {token_id=token_id; token_info=s.assets.token_info}
        


let token_metadata_main ((token_id,s):(nat * nft_asset_storage)):(operation list * nft_asset_storage) = (([]: operation list),s)