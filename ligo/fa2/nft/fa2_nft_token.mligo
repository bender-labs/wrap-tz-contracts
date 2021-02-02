(**
Implementation of the FA2 interface for the NFT contract supporting one
NFT class from ethereum.
Token id on tezos matches with token_id on ethereum
 *)
#if !FA2_NFT_TOKEN
#define FA2_NFT_TOKEN

#include "../common/fa2_interface.mligo"
#include "../common/fa2_errors.mligo"
#include "../common/lib/fa2_operator_lib.mligo"

type ledger = (token_id, address) big_map

type nft_token_storage = {
  ledger : ledger;
  operators : operator_storage;
  token_info: (string, bytes) map;
}

(** 
Retrieve the balances for the specified tokens and owners
@return callback operation
*)
let get_balance (p, ledger : balance_of_param * ledger) : operation =
  let to_balance = fun (r : balance_of_request) ->
    let owner = Big_map.find_opt r.token_id ledger in
    match owner with
    | None -> (failwith fa2_token_undefined : balance_of_response)
    | Some o ->
      let bal = if o = r.owner then 1n else 0n in
      { request = r; balance = bal; }
  in
  let responses = List.map to_balance p.requests in
  Tezos.transaction responses 0mutez p.callback

(**
Update leger balances according to the specified transfers. Fails if any of the
permissions or constraints are violated.
@param txs transfers to be applied to the ledger
@param validate_op function that validates of the tokens from the particular owner can be transferred. 
 *)
let transfer (txs, validate_op, ops_storage, ledger
    : (transfer list) * operator_validator * operator_storage * ledger) : ledger =
  (* process individual transfer *)
  let make_transfer = (fun (l, tx : ledger * transfer) ->
    List.fold 
      (fun (ll, dst : ledger * transfer_destination) ->
        if dst.amount = 0n
        then ll
        else if dst.amount <> 1n
        then (failwith fa2_insufficient_balance : ledger)
        else
          let owner = Big_map.find_opt dst.token_id ll in
          match owner with
          | None -> (failwith fa2_token_undefined : ledger)
          | Some o -> 
            if o <> tx.from_
            then (failwith fa2_insufficient_balance : ledger)
            else 
              let u = validate_op (o, Tezos.sender, dst.token_id, ops_storage) in
              Big_map.update dst.token_id (Some dst.to_) ll
      ) tx.txs l
  )
  in 
    
  List.fold make_transfer txs ledger


let fa2_main (param, storage : fa2_entry_points * nft_token_storage)
    : (operation  list) * nft_token_storage =
  match param with
  | Transfer txs ->
    let new_ledger = transfer 
      (txs, default_operator_validator, storage.operators, storage.ledger) in
    let new_storage = { storage with ledger = new_ledger; } in
    ([] : operation list), new_storage

  | Balance_of p ->
    let op = get_balance (p, storage.ledger) in
    [op], storage

  | Update_operators updates ->
    let new_ops = fa2_update_operators (updates, storage.operators) in
    let new_storage = { storage with operators = new_ops; } in
    ([] : operation list), new_storage


#endif