type mint_burn_tx = {
  owner : address,
  amount : nat
}

type mint_burn_tokens_param = list(mint_burn_tx)

type token_manager =
   Mint_tokens (mint_burn_tokens_param)
  | Burn_tokens (mint_burn_tokens_param)
;