#include "storage.mligo"


let bps_of (value, bps: nat * bps): nat = 
    value * bps / 10_000n

let compute_fees (value, bps: nat * bps):( nat * nat ) = 
  let fees = bps_of(value, bps) in
  let amount_to_mint : nat = (match Michelson.is_nat(value - fees) with
    | Some(n) -> n 
    | None -> (failwith("BAD_FEES"):nat)) in
  (amount_to_mint, fees)

let inc_token_balance (balances, key, value : balance_sheet * token_address * nat)
    : balance_sheet =
  let info_opt = Map.find_opt key balances.tokens in
  let new_balance = 
    match info_opt with
    | None -> value
    | Some info -> value + info
    in
  let tokens = Map.update key (Some new_balance) balances.tokens in
  { balances with tokens = tokens }

let check_fees_high_enough (v, min : nat * nat) =
  if v < min then failwith("FEES_TOO_LOW")

let check_nft_fees_high_enough (v, min : tez * tez) =
  if v < min then failwith("FEES_TOO_LOW")  

let check_amount_large_enough (v:nat) =
  if v < 1n then failwith("AMOUNT_TOO_SMALL")