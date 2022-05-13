#if !TOKEN_LIB
#define TOKEN_LIB

#include "./types.mligo"

// -----------------------------------------------------------------
// Helper
// -----------------------------------------------------------------

[@inline]
let get_balance_amt (key, ledger : address  * ledger) : nat =
  let bal_opt = Big_map.find_opt key ledger in
  match bal_opt with
  | None -> 0n
  | Some b -> b

[@inline]
let inc_balance (amt, owner, _token_id, ledger
    : nat * address * token_id * ledger) : ledger =
  let bal = get_balance_amt (owner, ledger) in
  let updated_bal = bal + amt in
  if updated_bal = 0n
  then Big_map.remove owner ledger
  else Big_map.update owner (Some updated_bal) ledger 

[@inline]
let dec_balance (amt, owner, _token_id, ledger
    : nat * address * token_id * ledger) : ledger =
  let bal = get_balance_amt (owner, ledger) in
  match is_nat (bal - amt) with
  | None -> ([%Michelson ({| { FAILWITH } |} : string * (nat * nat) -> ledger)] (fa2_insufficient_balance, (amt, bal)) : ledger)
  | Some new_bal ->
    if new_bal = 0n
    then Big_map.remove owner ledger
    else Big_map.update owner (Some new_bal) ledger

[@inline]
let check_sender (from_ , store : address * storage): address =
  if (Tezos.sender = from_) then from_
  else
    let key: operator = { owner = from_; operator = Tezos.sender} in
    if Big_map.mem key store.assets.operators then
      from_
    else
     ([%Michelson ({| { FAILWITH } |} : string * unit -> address)]
        (fa2_not_operator, ()) : address)


[@inline]
let credit_to (amt, to_, token_id, ledger, total_supply : nat * address * nat * ledger * total_supply): (ledger * total_supply) =
  let current_total_supply = total_supply in
  let ledger = inc_balance(amt, to_, token_id, ledger) in
  let total_supply = current_total_supply + amt in
  (ledger, total_supply)

#endif