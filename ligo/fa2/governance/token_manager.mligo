(* 
    Mint and burn for governance token is a little bit special.
    It shouldn't affect the total supply, because it just means that the goverance comes and goes on both chains.
    If we want the baseDAO to always compute properly quorum threshold, the supply must represent all tokens in circulution
    on both chains. 

    Token manager API allows to:

      1. Create new toke types,
      2. Mint and burn tokens to some existing or new owner account.

    Burn operation fails if the owner holds less tokens then burn amount.
*)

#if !TOKEN_MANAGER
#define TOKEN_MANAGER

#include "types.mligo"
#include "token_helper.mligo"

[@inline]
let valid_token_id (id:nat):nat = 
    if id = unfrozen_token_id
    then id
    else (failwith "BAD_MINT_BURN":nat)

let mint_update_balances (txs, ledger : (mint_burn_tx list) * ledger) : ledger =
    let mint = fun (l, tx : ledger * mint_burn_tx) ->
        let token_id = valid_token_id(tx.token_id) in
        inc_balance (tx.amount, tx.owner, token_id, l)
    in List.fold mint txs ledger

let mint_tokens (param, storage : mint_burn_tokens_param * token_storage) 
    : token_storage =
    let new_ledger = mint_update_balances (param, storage.ledger) in
    let new_s = { storage with
      ledger = new_ledger;
    } in
    new_s

let burn_update_balances(txs, ledger : (mint_burn_tx list) * ledger) : ledger =
  let burn = fun (l, tx : ledger * mint_burn_tx) ->
    let token_id = valid_token_id(tx.token_id) in
    dec_balance (tx.amount, tx.owner, token_id, l) in

  List.fold burn txs ledger

let burn_tokens (param, storage : mint_burn_tokens_param * token_storage) 
    : token_storage =

    let new_ledger = burn_update_balances (param, storage.ledger) in
    let new_s = { storage with
      ledger = new_ledger;
    } in
    new_s

let token_manager (param, s : token_manager * storage)
    : return  =
  match param with

  | Mint_tokens param -> 
    let new_s = mint_tokens (param, s.assets) in
    ([] : operation list), {s with assets = new_s }

  | Burn_tokens param -> 
    let new_s = burn_tokens (param, s.assets) in
    ([] : operation list), {s with assets = new_s}

#endif