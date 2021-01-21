#if !FA2_INTERFACE
#define FA2_INTERFACE

type fa2_token_id = nat;

type mint_burn_tx = 
[@layout:comb]
{
  owner : address,
  token_id : fa2_token_id,
  amount : nat
}

type mint_burn_tokens_param = list(mint_burn_tx)

type token_metadata =
[@layout:comb]
{
  token_id : fa2_token_id,
  extras : map(string, bytes)
};

type token_manager =
    Create_token (token_metadata)
  | Mint_tokens (mint_burn_tokens_param)
  | Burn_tokens (mint_burn_tokens_param)
;

type pause_param = 
[@layout:comb]
{
  token_id : fa2_token_id,
  paused : bool
}


type token_admin = 
   Set_admin (address)
  | Confirm_admin 
  | Pause (list(pause_param))
;


type fa2_token_metadata_storage = big_map(fa2_token_id, token_metadata);

type ledger = big_map((address, fa2_token_id), nat);

type token_total_supply = big_map(fa2_token_id, nat);

type operator_storage = big_map((address, (address , fa2_token_id)), unit);

type multi_token_storage = {
  ledger : ledger,
  operators : operator_storage,
  token_total_supply : token_total_supply,
  token_metadata : fa2_token_metadata_storage
};

type paused_tokens_set = big_map(fa2_token_id, unit);

type token_admin_storage = {
  admin : address,
  pending_admin : option(address),
  paused : paused_tokens_set
};

type fa2_storage = {
  admin : unit,
  assets : multi_token_storage,
  metadata : unit
};

#endif