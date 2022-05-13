#include "./types.mligo"
#include "../common/fa2_errors.mligo"
#include "./token_helper.mligo"


// -----------------------------------------------------------------
// Transfer
// -----------------------------------------------------------------

let transfer_item (store, ti : storage * transfer): storage =
  let transfer_one (store, tx : storage * transfer_destination): storage =
    let valid_from_ = check_sender (ti.from_, store) in
    if tx.amount = 0n then store
    else (
      let valid_token_id =
        if tx.token_id = unfrozen_token_id then tx.token_id
        else (failwith fa2_token_undefined : token_id)
        
      in
      let ledger = store.assets.ledger in
      let ledger = dec_balance(tx.amount, valid_from_, valid_token_id, ledger) in
      let ledger = inc_balance(tx.amount, tx.to_, valid_token_id, ledger) in
      { store with 
        assets = {
          store.assets with ledger = ledger
        }
      }
    )
  in List.fold transfer_one ti.txs store

let transfer (params, store : transfer list * storage): return =
  let store = List.fold transfer_item params store in
  (([] : operation list), store)


// -----------------------------------------------------------------
// Balance of
// -----------------------------------------------------------------

[@inline]
let validate_token_type (token_id, _store : token_id * token_storage): token_id =
  if (token_id = unfrozen_token_id) then
    token_id
  else ([%Michelson ({| { FAILWITH } |} : string * unit -> token_id)]
          (fa2_token_undefined, ()) : token_id)

let balance_of (params, store : balance_of_param * storage): return =
  let check_one (req : balance_of_request): balance_of_response =
    let _valid_token_id = validate_token_type(req.token_id, store.assets) in
    let bal =
      match Big_map.find_opt req.owner store.assets.ledger with
        Some bal -> bal
      | None -> 0n
    in { request = req; balance = bal}
  in
  let result = List.map check_one params.requests in
  let transfer_operation = Tezos.transaction result 0mutez params.callback
  in (([transfer_operation] : operation list), store)

// -----------------------------------------------------------------
// Update operators entrypoint
// -----------------------------------------------------------------
[@inline]
let validate_operator_token (token_id : token_id): token_id =
  if (token_id = unfrozen_token_id) then
    token_id
  else 
    (failwith("OPERATION_PROHIBITED") : token_id)
  

let update_one (store, param: token_storage * update_operator): token_storage =
  let (operator_update, operator_param) =
    match param with
      Add_operator p -> (Some unit, p)
    | Remove_operator p -> ((None : unit option), p)
  in
  let _valid_token_id = validate_operator_token (operator_param.token_id) in
  if (Tezos.sender = operator_param.owner) then
    let key: operator = { owner = operator_param.owner; operator = operator_param.operator} in
    let updated_operators = Big_map.update key operator_update store.operators
    in  { store with
          operators = updated_operators
        }
  else
    (failwith(fa2_not_owner) : token_storage)

let update_operators (params, store : update_operator list * storage): return =
  let new_assets = List.fold update_one params store.assets in
  (([] : operation list), {store with assets = new_assets })

let fa2_main (params, store: fa2_entry_points * storage): return = 
  match params with 
  | Transfer p -> transfer(p, store)
  | Balance_of p -> balance_of(p, store)
  | Update_operators p -> update_operators(p, store)
