#include "./base_dao_interface.mligo"
#include "./token_helper.mligo"

let ensure_proposal_id (id, store: token_id * token_storage): token_storage = 
    match Big_map.find_opt id store.total_supply with
    | Some v -> store
    | None -> {store with total_supply = Big_map.add id 0n store.total_supply}

let lock_one (store, p: token_storage * lock_unlock): token_storage = 
    let store = ensure_proposal_id(p.proposal_id, store) in
    let ledger = store.ledger in
    let total_supply = store.total_supply in
    let (ledger, total_supply) = debit_from(p.amount, p.from_, frozen_token_id, ledger, total_supply) in
    let (ledger, total_supply) = credit_to(p.amount, p.from_, p.proposal_id, ledger, total_supply) in
    { store with 
    ledger = ledger ; total_supply = total_supply
    }
    
let lock (p, s: lock_unlock_param * storage): return = 
    let new_assets = List.fold lock_one p s.assets in
    ([]:operation list), {s with assets = new_assets }


let unlock_one (store, p: token_storage * lock_unlock): token_storage = 
    let ledger = store.ledger in
    let total_supply = store.total_supply in
    let (ledger, total_supply) = debit_from(p.amount, p.from_, p.proposal_id, ledger, total_supply) in
    let (ledger, total_supply) = credit_to(p.amount, p.from_, frozen_token_id, ledger, total_supply) in
    { store with 
    ledger = ledger ; total_supply = total_supply
    }
    
let unlock (p, s: lock_unlock_param * storage): return = 
    let new_assets = List.fold unlock_one p s.assets in
    ([]:operation list), {s with assets = new_assets }

let get_total_supply(c, store: nat contract * storage): operation = 
    let supply = 
        match Big_map.find_opt unfrozen_token_id store.assets.total_supply with
        | Some v -> v
        | None -> 0n
        in
    Tezos.transaction supply 0tez c

let confirm_dao_migration (store: dao_storage): dao_storage = 
    match store.pending_contract with 
        | Some v -> 
            if v = Tezos.sender
            then {store with pending_contract = (None: address option) ; contract = v}
            else (failwith "WRONG_MIGRATION":dao_storage) 
        | None -> (failwith "NO_RUNNING_MIGRATION":dao_storage)
    

let check_is_dao (s: storage): storage = 
    if Tezos.sender = s.dao.contract then s
    else (failwith "UNAUTHORIZED":storage)

let base_dao_main (p, s : base_dao_entry_points * storage) : return = 
    match p with 
    | Confirm_dao_migration -> 
        ([]:operation list), {s with dao = confirm_dao_migration(s.dao)}
    | Get_total_supply p -> [get_total_supply(p, s)], s
    | Lock p -> 
        let s = check_is_dao(s) in
        lock(p, s)
    | Unlock p -> 
        let s = check_is_dao(s) in
        unlock(p, s)
    | Migrate_dao p -> 
        let s = check_is_dao(s) in
        ([]:operation list), {s with dao = {s.dao with pending_contract = Some p}}