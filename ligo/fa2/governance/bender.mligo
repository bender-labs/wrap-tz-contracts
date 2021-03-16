#include "./types.mligo"
#include "./role_helper.mligo"

type distribution = 
[@layout:comb]
{
    to_: address;
    amount: nat;
}

type distribute_param = distribution list

type bender_entry_points = 
| Distribute of distribute_param
| Migrate_bender of address
| Confirm_bender_migration

let check_is_bender (store: storage): storage = 
    if Tezos.sender = store.bender.role.contract
    then store
    else (failwith "UNAUTHORIZED":storage)


let distribute (p, store: distribute_param * storage): return =
    let distribute_one (acc, p: (nat * token_storage) * distribution): nat * token_storage = 
        let (distributed, store) = acc in
        let ledger = store.ledger in
        let total_supply = store.total_supply in
        let (ledger, total_supply) = credit_to(p.amount, p.to_, unfrozen_token_id, ledger, total_supply) in
        distributed + p.amount, { store with 
        ledger = ledger ; total_supply = total_supply
        }
    in 
    let (distributed, new_assets) = List.fold distribute_one p (0n, store.assets) in
    let new_distributed = distributed + store.bender.distributed in
    if new_distributed <= store.bender.max_supply
    then ([]: operation list), {store with assets = new_assets; bender = {store.bender with distributed = new_distributed}}
    else (failwith "RESERVE_DEPLETED": return)

let bender_main (p, store: bender_entry_points * storage): return = 
    match p with 
    | Distribute p -> 
        let store = check_is_bender(store) in
        distribute(p, store)
    | Migrate_bender p -> 
        let store = check_is_bender(store) in
        ([]: operation list), {store with bender = {store.bender with role = {store.bender.role with pending_contract = Some p}}}
    | Confirm_bender_migration -> 
        ([]:operation list), {store with bender = { store.bender with role = confirm_migration(store.bender.role)}}