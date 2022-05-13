(*
  One of the possible implementations of token management API which can create
  mint and burn non-fungible tokens.
  
  Mint operation creates a new type of NFTs and assign them to owner accounts.
  Burn operation removes existing NFT type and removes its tokens from owner
  accounts.
*)

#if !TOKEN_MANAGER
#define TOKEN_MANAGER

#include "fa2_nft_token.mligo"

let invalid_mint_burn_param = "INVALID_MINT_BURN_PARAMETER"

let validate_mint_param (p : mint_burn_tx)= 
  if p.amount <> 1n then failwith (invalid_mint_burn_param)

let check_token_absent (p, s : mint_burn_tx * nft_token_storage) = 
  if Big_map.mem p.token_id s.ledger
  then failwith "USED_TOKEN_ID"

let mint_token (s, p : nft_token_storage * mint_burn_tx) : nft_token_storage =
  let _ignore = validate_mint_param(p) in
  let _ignore = check_token_absent(p, s) in
  {s with ledger = Big_map.add p.token_id p.owner s.ledger}


let mint_tokens (p, s : mint_burn_tokens_param * nft_token_storage) : nft_token_storage =
  List.fold mint_token p s


let burn_token (s, p : nft_token_storage * mint_burn_tx) : nft_token_storage = 
  let _ignore = validate_mint_param(p) in
  let maybe_token = Big_map.find_opt p.token_id s.ledger in
  match maybe_token with
  | Some addr -> 
    if addr = p.owner
    then {s with ledger = Big_map.remove p.token_id s.ledger}
    else (failwith invalid_mint_burn_param : nft_token_storage)
  | None -> (failwith invalid_mint_burn_param : nft_token_storage)

let burn_tokens (p, s : mint_burn_tokens_param * nft_token_storage) : nft_token_storage =
  List.fold burn_token p s

let token_manager (param, s : token_manager * nft_token_storage)
    : (operation list) * nft_token_storage =
  let new_s = match param with
  | Mint_tokens p -> mint_tokens (p, s)
  | Burn_tokens p -> burn_tokens (p, s)
  in
  ([] : operation list), new_s

#endif
