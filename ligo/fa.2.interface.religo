type mint_burn_tx = 
[@layout:comb]
{
  owner : address,
  amount : nat
}

type mint_burn_tokens_param = list(mint_burn_tx)

type token_manager =
   Mint_tokens (mint_burn_tokens_param)
  | Burn_tokens (mint_burn_tokens_param)
;

type fa2_ledger = big_map(address, nat);

type fa2_token_id = nat;

type k = (address, fa2_token_id);

type fa2_operator_storage = big_map((address, k), unit);

type fa2_token_metadata = 
[@layout:comb]
{
  token_id : fa2_token_id,
  symbol : string,
  name : string,
  decimals : nat,
  extras : map(string, string)
};

type fa2_token_metadata_michelson = michelson_pair_right_comb(fa2_token_metadata)

type fa2_storage = {
  admin: {
    admin : address,
    pending_admin : option(address),
    paused : bool
  },
  assets: {
    ledger : fa2_ledger,
    operators : fa2_operator_storage,
    token_metadata : big_map(nat, fa2_token_metadata_michelson),
    total_supply : nat
  }
};

type fa2_entrypoints = unit;