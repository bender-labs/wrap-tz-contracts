#include "tokens.mligo"

type pause_tokens_param = {
    token: eth_address;
    paused: bool;
}

type assets_admin_entrypoints = 
| Change_tokens_administrator of address * address list
| Confirm_tokens_administrator of address list
| Pause_tokens of pause_tokens_param list

let confirm_admin (p, s: address list * assets_storage) : (operation list * assets_storage) = 
    let create_op : address -> operation = 
        fun (a: address) ->
            let ep = token_admin_entry_point(a) in
            Tezos.transaction (Confirm_admin) 0mutez ep
        in
    let ops = List.map create_op p in
    ops, s

let pause_fungible (p, s: pause_tokens_param * assets_storage) : operation option =
    match Map.find_opt p.token s.fungible_tokens with
    | Some token_address -> 
        let (addr, id) = token_address in
        let ep = token_admin_entry_point(addr) in
        Some (Tezos.transaction (Pause [{token_id=id; paused=p.paused}]) 0mutez ep)
    | None -> (None : operation option)

let pause_nft (p, s: pause_tokens_param * assets_storage) : operation = 
    let addr = get_nft_contract(p.token, s.nfts) in
    let ep = token_admin_entry_point(addr) in
    Tezos.transaction (Pause [{token_id=0n; paused=p.paused}]) 0mutez ep

let pause_tokens ((p,s) : (pause_tokens_param list * assets_storage)) : (operation list * assets_storage) = 
    let create_op : pause_tokens_param -> operation = 
        fun (p:pause_tokens_param) -> 
            match pause_fungible(p, s) with
            | Some v -> v
            | None -> pause_nft(p, s)
        in
    
    let ops = List.map create_op p in
    ops, s

let change_tokens_administrator ( p, s : (address * address list) * assets_storage) : (operation list * assets_storage) =
    let (new_admin, contracts) = p in
    let create_op : address -> operation = 
        fun (a: address) ->
            let ep = token_admin_entry_point(a) in
            Tezos.transaction (Set_admin new_admin) 0mutez ep
        in

    let ops = List.map create_op contracts in
    ops,s


let assets_admin_main ((p, s): (assets_admin_entrypoints * assets_storage)): (operation list * assets_storage) =
    match p with
    | Change_tokens_administrator(p) -> change_tokens_administrator(p, s)
    | Confirm_tokens_administrator(p) -> confirm_admin(p, s)
    | Pause_tokens(p) -> pause_tokens(p, s)
