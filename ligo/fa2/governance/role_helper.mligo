#include "./types.mligo"

let confirm_migration (store: role_storage): role_storage = 
    match store.pending_contract with 
        | Some v -> 
            if v = Tezos.sender
            then {store with pending_contract = (None: address option) ; contract = v}
            else (failwith "WRONG_MIGRATION":role_storage) 
        | None -> (failwith "NO_RUNNING_MIGRATION":role_storage)