#if !GOV_TYPES
#define GOV_TYPES

#include "../common/fa2_interface.mligo"
#include "../fa2_modules/token_admin.mligo"

type ledger = ((address * token_id), nat) big_map

type operator =
  [@layout:comb]
  { owner : address
  ; operator : address
  }
type operators = (operator, unit) big_map

type total_supply = (token_id, nat) map

type token_storage = {
  ledger : ledger;
  operators : operators;
  total_supply : total_supply;
  token_metadata : token_metadata_storage;
}

let unfrozen_token_id: nat = 0n

let frozen_token_id: nat = 1n

type dao_storage = {
    contract: address;
    pending_contract: address option;
}

type storage = {
    admin: token_admin_storage;
    assets: token_storage;
    dao: dao_storage;
}

type return = operation list * storage

#endif