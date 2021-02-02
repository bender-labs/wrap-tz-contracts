#include "tokens.mligo"

type pause_tokens_param = {
    token: eth_address;
    paused: bool;
}

type assets_admin_entrypoints = 
| Change_tokens_administrator of address
| Confirm_tokens_administrator of address
| Pause_tokens of pause_tokens_param list



let confirm_admin ((p, s):(address * assets_storage)): (operation list * assets_storage) = 
    let ep = token_admin_entry_point(p) in
    ([Tezos.transaction (Confirm_admin) 0mutez ep], s)


let pause_tokens ((p,s) : (pause_tokens_param list * assets_storage)) : (operation list * assets_storage) = 
    let create_op : pause_tokens_param -> operation = 
        fun (p:pause_tokens_param) -> 
            let (addr, id) : token_adress = get_fa2_token_id(p.token, s.fungible_tokens) in
            let ep = token_admin_entry_point(addr) in
            Tezos.transaction (Pause [{token_id=id; paused=p.paused}]) 0mutez ep
        in
    
    let ops = List.map create_op p in
    (ops, s)

// warning. this method could explode gas limit. 
let change_tokens_administrator ((p, s):(address * assets_storage)):(operation list * assets_storage) =
    let folded : ((address set) * (eth_address * (address * nat))) -> address set = 
        fun ((acc,(eth_address,(contract, id))):((address set) * (eth_address * (address * nat)))) -> Set.add contract acc
        in

    let contracts = Map.fold folded s.fungible_tokens (Set.empty : address set) in

    let create_op : (operation list * address) -> operation list = 
        fun ((acc, contract):(operation list * address)) -> 
            let ep = token_admin_entry_point(contract) in
            (Tezos.transaction (Set_admin p) 0mutez ep) :: acc
        in
    
    let ops: operation list = Set.fold create_op contracts ([]:operation list) in
    (ops, s)


let assets_admin_main ((p, s): (assets_admin_entrypoints * assets_storage)): (operation list * assets_storage) =
    match p with
    | Change_tokens_administrator(p) -> change_tokens_administrator(p, s)
    | Confirm_tokens_administrator(p) -> confirm_admin(p, s)
    | Pause_tokens(p) -> pause_tokens(p, s)
