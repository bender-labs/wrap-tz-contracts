#if !MULTI_FA_TYPES
#define MULTI_FA_TYPES

#include "../common/fa2_interface.mligo"
#include "../common/fa2_errors.mligo"
#include "../fa2_modules/token_admin.mligo"

type ledger = ((address * token_id), nat) big_map

type operator_storage = ((address * (address * token_id)), unit) big_map

(* token_id -> total_supply *)
type token_total_supply = (token_id, nat) big_map

type multi_token_storage = {
  ledger : ledger;
  operators : operator_storage;
  token_total_supply : token_total_supply;
  token_metadata : token_metadata_storage;
}

type multi_asset_storage = {
  admin : token_admin_storage;
  assets : multi_token_storage;
  metadata : contract_metadata;
}

type return = (operation list) * multi_asset_storage

#endif