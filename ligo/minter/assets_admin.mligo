#include "tokens_lib.mligo"


type pause_tokens_param = {
    contract: address;
    tokens: token_id list;
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

let pause_tokens_in_contract (p:pause_tokens_param) : operation = 
    let ep = token_admin_entry_point(p.contract) in
    let params = 
        List.map (fun (t:token_id) -> {token_id=t; paused=p.paused}) p.tokens
        in
    Tezos.transaction (Pause params) 0mutez ep    

let pause_tokens (p,s: pause_tokens_param list * assets_storage) : (operation list * assets_storage) = 
    let ops = List.map pause_tokens_in_contract p in
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
