#if !TOKEN_LIB
#define TOKEN_LIB

#include "./types.mligo"

// -----------------------------------------------------------------
// Helper
// -----------------------------------------------------------------

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
  match Big_map.find_opt (from_, token_id) ledger with
    Some bal ->

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

      in (match Michelson.is_nat (bal - amt) with
            Some new_bal ->
              let ledger = Big_map.update (from_, token_id) (Some new_bal) ledger in
              let total_supply = Map.update token_id (Some new_total_supply) total_supply in
              (ledger, total_supply)
          | None ->
              ([%Michelson ({| { FAILWITH } |} : string * (nat * nat) -> (ledger * total_supply))] (fa2_insufficient_balance, (amt, bal)) : (ledger * total_supply))
         )

  | None ->
      if (amt = 0n) then (ledger, total_supply) // We allow 0 transfer
      else
        ([%Michelson ({| { FAILWITH } |} : string * (nat * nat) -> (ledger * total_supply))] (fa2_insufficient_balance, (amt, 0n)) : (ledger * total_supply))

[@inline]
let credit_to (amt, to_, token_id, ledger, total_supply : nat * address * nat * ledger * total_supply): (ledger * total_supply) =
  match Map.find_opt token_id total_supply with
    Some current_total_supply ->
      let new_bal =
        match Big_map.find_opt (to_, token_id) ledger with
          Some bal -> bal + amt
        | None -> amt
      in  let ledger = Big_map.update (to_, token_id) (Some new_bal) ledger in
          let total_supply = Map.update token_id (Some (current_total_supply + amt)) total_supply in
          (ledger, total_supply)
  | None ->
      (failwith(fa2_token_undefined) : (ledger * total_supply))

#endif