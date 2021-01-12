#include "tokens.religo"

type assets_admin_entrypoints = 
    Change_tokens_administrator(address)
    | Confirm_tokens_administrator
    | Pause_tokens(list(pause_param))
;

let confirm_admin = (s : assets_storage): (list(operation), assets_storage) => {
    let ep = token_admin_entry_point(s);
    ([Tezos.transaction(Confirm_admin, 0mutez, ep)], s)
}

let pause_tokens = ((s,p):(assets_storage, list(pause_param))):(list(operation), assets_storage) =>  {
    let ep = token_admin_entry_point(s);
    ([Tezos.transaction(Pause(p), 0mutez, ep)], s);
}

let change_tokens_administrator = ((s, p):(assets_storage, address)):(list(operation), assets_storage) => {
    let ep = token_admin_entry_point(s);
    ([Tezos.transaction(Set_admin(p), 0mutez, ep)], s);
}

let assets_admin_main = ((p, s): (assets_admin_entrypoints, assets_storage)): (list(operation), assets_storage) => {
    switch(p) {
        | Change_tokens_administrator(p) => change_tokens_administrator(s, p);
        | Confirm_tokens_administrator => confirm_admin(s);
        | Pause_tokens(p) => pause_tokens(s, p);
    };
}