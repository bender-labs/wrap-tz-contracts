(*
  One of the possible implementations of admin API for FA2 contract.
  The admin API can change an admin address using two step confirmation pattern and
  pause/unpause transfer per token type.
  Only current admin can initiate those operations.
  
  Other entry points may guard their access using helper functions
  `fail_if_not_admin` and `fail_if_paused`.
*)

#if !TOKEN_ADMIN
#define TOKEN_ADMIN

#include "../common/fa2_interface.mligo"

type paused_tokens_set = (token_id, unit) big_map

type token_admin_storage = {
  admin : address;
  pending_admin : address option;
  paused : paused_tokens_set;
  minter: address;
}

let set_admin (new_admin, s : address * token_admin_storage) : token_admin_storage =
  { s with pending_admin = Some new_admin; }

let confirm_new_admin (s : token_admin_storage) : token_admin_storage =
  match s.pending_admin with
  | None -> (failwith "NO_PENDING_ADMIN" : token_admin_storage)
  | Some pending ->
    if Tezos.sender = pending
    then { s with 
      pending_admin = (None : address option);
      admin = Tezos.sender;
    }
    else (failwith "NOT_A_PENDING_ADMIN" : token_admin_storage)


let pause (tokens, s: (pause_param list) * token_admin_storage) : token_admin_storage =
  let new_paused = List.fold 
    (fun (paused_set, t : paused_tokens_set * pause_param) -> 
      if t.paused
      then Big_map.add t.token_id unit paused_set
      else Big_map.remove t.token_id paused_set
    )
    tokens s.paused in
  { s with paused = new_paused; }

let fail_if_not_admin (a : token_admin_storage) : token_admin_storage =
  if Tezos.sender <> a.admin
  then (failwith "NOT_AN_ADMIN": token_admin_storage)
  else a

let fail_if_not_minter (a : token_admin_storage) : token_admin_storage =
  if Tezos.sender <> a.minter
  then (failwith "NOT_A_MINTER": token_admin_storage)
  else a

let fail_if_paused_tokens (transfers, paused : transfer list * paused_tokens_set) : unit =
  List.iter 
    (fun (tx: transfer) ->
      List.iter (fun (txd : transfer_destination) -> 
        if Big_map.mem txd.token_id paused
        then failwith "TOKEN_PAUSED"
        else unit
      ) tx.txs
    ) transfers

let fail_if_paused (a, param : token_admin_storage * fa2_entry_points) : unit =
  match param with
  | Balance_of _ -> unit
  | Update_operators _ -> unit
  | Transfer transfers -> fail_if_paused_tokens(transfers, a.paused)


let token_admin (param, s : token_admin * token_admin_storage)
    : (operation list) * token_admin_storage =
  match param with
  | Set_admin new_admin ->
    let s = fail_if_not_admin s in
    let new_s = set_admin (new_admin, s) in
    (([]: operation list), new_s)

  | Confirm_admin ->
    let new_s = confirm_new_admin s in
    (([]: operation list), new_s)

  | Pause tokens ->
    let s = fail_if_not_admin s in
    let new_s = pause (tokens, s) in
    (([]: operation list), new_s)
  | Set_minter p ->
    let s = fail_if_not_admin s in

    ([]: operation list), {s with minter = p}

#endif
