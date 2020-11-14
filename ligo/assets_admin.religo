#include "tokens.religo"

type assets_admin_entrypoints = 
    Change_tokens_administrator
    | Pause_token

let assets_admin_main = ((p, s): (assets_admin_entrypoints, assets_storage)): (list(operation), assets_storage) => {
    switch(p) {
        | Change_tokens_administrator => (failwith ("Not implemented"):(list(operation), assets_storage));
        | Pause_token => (failwith ("Not implemented"):(list(operation), assets_storage));
    };
}