#include "./types.mligo"
#include "./role_helper.mligo"
#include "./token_helper.mligo"

type distribution = 
[@layout:comb]
{
    to_: address;
    amount: nat;
}

type distribute_param = distribution list

type oracle_entry_points = 
| Distribute of distribute_param
| Migrate_oracle of address
| Confirm_oracle_migration

let check_is_oracle (store: storage): storage = 
    if Tezos.sender = store.oracle.role.contract
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
    let new_distributed = distributed + store.oracle.distributed in
    if new_distributed <= store.oracle.max_supply
    then ([]: operation list), {store with assets = new_assets; oracle = {store.oracle with distributed = new_distributed}}
    else (failwith "RESERVE_DEPLETED": return)

let oracle_main (p, store: oracle_entry_points * storage): return = 
    match p with 
    | Distribute p -> 
        let store = check_is_oracle(store) in
        distribute(p, store)
    | Migrate_oracle p -> 
        let store = check_is_oracle(store) in
        ([]: operation list), {store with oracle = {store.oracle with role = {store.oracle.role with pending_contract = Some p}}}
    | Confirm_oracle_migration -> 
        ([]:operation list), {store with oracle = { store.oracle with role = confirm_migration(store.oracle.role)}}