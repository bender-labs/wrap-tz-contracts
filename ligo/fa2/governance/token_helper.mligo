#if !TOKEN_LIB
#define TOKEN_LIB

#include "./types.mligo"

// -----------------------------------------------------------------
// Helper
// -----------------------------------------------------------------

[@inline]
let get_balance_amt (key, ledger : (address * token_id) * ledger) : nat =
  let bal_opt = Big_map.find_opt key ledger in
  match bal_opt with
  | None -> 0n
  | Some b -> b

[@inline]
let inc_balance (amt, owner, token_id, ledger
    : nat * address * token_id * ledger) : ledger =
  let key = owner, token_id in
  let bal = get_balance_amt (key, ledger) in
  let updated_bal = bal + amt in
  if updated_bal = 0n
  then Big_map.remove key ledger
  else Big_map.update key (Some updated_bal) ledger 

[@inline]
let dec_balance (amt, owner, token_id, ledger
    : nat * address * token_id * ledger) : ledger =
  let key = owner, token_id in
  let bal = get_balance_amt (key, ledger) in
  match Michelson.is_nat (bal - amt) with
  | None -> ([%Michelson ({| { FAILWITH } |} : string * (nat * nat) -> ledger)] (fa2_insufficient_balance, (amt, bal)) : ledger)
  | Some new_bal ->
    if new_bal = 0n
    then Big_map.remove key ledger
    else Big_map.update key (Some new_bal) ledger

[@inline]
let check_sender (from_ , store : address * storage): address =
  if (Tezos.sender = store.admin.admin) then from_
  else if (Tezos.sender = from_) then from_
  else
    let key: operator = { owner = from_; operator = sender} in
    if Big_map.mem key store.assets.operators then
      from_
    else
     ([%Michelson ({| { FAILWITH } |} : string * unit -> address)]
        (fa2_not_operator, ()) : address)


[@inline]
let debit_from (amt, from_, token_id, ledger, total_supply: nat * address * token_id * ledger * total_supply): (ledger * total_supply) =
  let new_total_supply =
    match Map.find_opt token_id total_supply with
      Some current_total_supply ->
        (match Michelson.is_nat (current_total_supply - amt) with
          Some new_total_supply ->
            new_total_supply
        | None ->
            (failwith("NEGATIVE_TOTAL_SUPPLY") : nat)
        )
    | None ->
        (failwith(fa2_token_undefined) : nat)
    in
  let new_ledger = dec_balance(amt, from_, token_id, ledger) in
  let total_supply = 
    if new_total_supply = 0n && token_id <> frozen_token_id && token_id <> unfrozen_token_id
    then Map.remove token_id total_supply
    else Map.update token_id (Some new_total_supply) total_supply in
  (new_ledger, total_supply)

[@inline]
let credit_to (amt, to_, token_id, ledger, total_supply : nat * address * nat * ledger * total_supply): (ledger * total_supply) =
  let current_total_supply = 
  match Map.find_opt token_id total_supply with
  | Some v -> v
  | None -> 0n in
  let ledger = inc_balance(amt, to_, token_id, ledger) in
  let total_supply = Map.update token_id (Some (current_total_supply + amt)) total_supply in
  (ledger, total_supply)

#endif