#include "tokens.religo"

type pause_tokens_param = {
    token: eth_address,
    paused: bool
};

type assets_admin_entrypoints = 
    Change_tokens_administrator(address)
    | Confirm_tokens_administrator(address)
    | Pause_tokens(list(pause_tokens_param))
;


let confirm_admin = (p:address, s:assets_storage): (list(operation), assets_storage) => {
    let ep = token_admin_entry_point(p);
    ([Tezos.transaction(Confirm_admin, 0mutez, ep)], s)
}

let pause_tokens = ((p,s) : (list(pause_tokens_param), assets_storage)) : (list(operation), assets_storage) =>  {
    let create_op = ( p : pause_tokens_param):operation => {
        let (addr, id) : token_adress = token_id(p.token, s.tokens);
        let ep = token_admin_entry_point(addr);
        Tezos.transaction(Pause([{token_id:id, paused:p.paused}]), 0mutez, ep);
    };
    let ops = List.map(create_op, p);
    (ops, s);
}

// warning. this method could explode gas limit. 
let change_tokens_administrator = ((p, s):(address, assets_storage)):(list(operation), assets_storage) => {
    let folded = ((acc,(eth_address,(contract, id))): (set(address), (eth_address, (address, nat)))) => Set.add(contract, acc);
    let contracts = Map.fold (folded, s.tokens, (Set.empty:set(address)));

    let create_op = (acc:list(operation), contract:address):list(operation) => {
        let ep = token_admin_entry_point(contract);
        [Tezos.transaction(Set_admin(p), 0mutez, ep), ...acc];
    };
    let ops: list(operation) = Set.fold(create_op, contracts, []:list(operation));
    (ops, s);
}

let assets_admin_main = ((p, s): (assets_admin_entrypoints, assets_storage)): (list(operation), assets_storage) => {
    switch(p) {
        | Change_tokens_administrator(p) => change_tokens_administrator(p, s);
        | Confirm_tokens_administrator(p) => confirm_admin(p, s);
        | Pause_tokens(p) => pause_tokens(p, s);
    };
}