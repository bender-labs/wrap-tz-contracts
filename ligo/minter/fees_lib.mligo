#include "storage.mligo"


let bps_of (value, bps: nat * bps): nat = 
    value * bps / 10_000n

let compute_fees (value, bps: nat * bps):( nat * nat ) = 
  let fees = bps_of(value, bps) in
  let amount_to_mint : nat = (match Michelson.is_nat(value - fees) with
    | Some(n) -> n 
    | None -> (failwith("BAD_FEES"):nat)) in
  (amount_to_mint, fees)

let token_balance (ledger, target ,token : token_ledger * address * token_address): nat =
    let key = target, token in
    let info_opt = Big_map.find_opt key ledger in
    match info_opt with
    | Some n -> n
    | None -> 0n

let xtz_balance (ledger, target  : xtz_ledger * address ): tez =
    let info_opt = Big_map.find_opt target ledger in
    match info_opt with
    | Some n -> n
    | None -> 0tez

let inc_token_balance (ledger, target, token, value : token_ledger * address * token_address * nat)
    : token_ledger =
  let current_balance = token_balance(ledger, target, token) in
  let key = target, token in
  Big_map.update key (Some (value + current_balance)) ledger

let inc_xtz_balance (ledger, target, value : xtz_ledger * address  * tez)
    : xtz_ledger =
  let info_opt = Big_map.find_opt target ledger in
  let new_balance = 
    match info_opt with
    | None -> value
    | Some info -> value + info
    in
  Big_map.update target (Some new_balance) ledger

let check_fees_high_enough (v, min : nat * nat) =
  if v < min then failwith("FEES_TOO_LOW")

let check_nft_fees_high_enough (v, min : tez * tez) =
  if v < min then failwith("FEES_TOO_LOW")