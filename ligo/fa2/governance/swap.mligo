#include "./types.mligo"
#include "./token_helper.mligo"

type swap_entry_points = 
| Freeze of nat
| Unfreeze of nat

let freeze (amt, store: nat * storage): storage =
    let ledger = store.assets.ledger in
    let total_supply = store.assets.total_supply in
    let (ledger, total_supply) = debit_from(amt, Tezos.sender, unfrozen_token_id, ledger, total_supply) in
    let (ledger, total_supply) = credit_to(amt, Tezos.sender, frozen_token_id, ledger, total_supply) in
    { store with 
        assets = {
          store.assets with ledger = ledger ; total_supply = total_supply
        }
    }
    

let unfreeze (amt, store: nat * storage): storage =
    let ledger = store.assets.ledger in
    let total_supply = store.assets.total_supply in
    let (ledger, total_supply) = debit_from(amt, Tezos.sender, frozen_token_id, ledger, total_supply) in
    let (ledger, total_supply) = credit_to(amt, Tezos.sender, unfrozen_token_id, ledger, total_supply) in
    { store with 
        assets = {
          store.assets with ledger = ledger ; total_supply = total_supply
        }
    }

let swap_main (p, store : swap_entry_points * storage) : return = 
    match p with
    | Freeze p -> ([]: operation list), freeze(p, store)
    | Unfreeze p -> ([]: operation list), unfreeze(p, store)