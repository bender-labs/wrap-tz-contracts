#include "tokens.religo"

type assets_admin_entrypoints = 
    Change_tokens_administrator
    | Confirm_tokens_administrator
    | Pause_token
;

let confirm_admin = (s : assets_storage): (list(operation), assets_storage) => {
    let ep = token_admin_entry_point(s);
    ([Tezos.transaction(Confirm_admin, 0mutez, ep)], s)
}

let assets_admin_main = ((p, s): (assets_admin_entrypoints, assets_storage)): (list(operation), assets_storage) => {
    switch(p) {
        | Change_tokens_administrator => (failwith ("Not implemented"):(list(operation), assets_storage));
        | Confirm_tokens_administrator => confirm_admin(s);
        | Pause_token => (failwith ("Not implemented"):(list(operation), assets_storage));
    };
}