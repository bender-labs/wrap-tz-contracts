#if !GOV_TYPES
#define GOV_TYPES

#include "../common/fa2_interface.mligo"
#include "../common/fa2_errors.mligo"
#include "../fa2_modules/simple_admin.mligo"

type ledger = (address, nat) big_map

type operator =
  [@layout:comb]
  { owner : address
  ; operator : address
  }
type operators = (operator, unit) big_map

type total_supply = nat

type token_storage = {
  ledger : ledger;
  operators : operators;
  total_supply : total_supply;
  token_metadata : token_metadata_storage;
}

let unfrozen_token_id: nat = 0n

type role_storage = {
    contract: address;
    pending_contract: address option;
}

type bender_storage = {
  role: role_storage;
  max_supply: nat;
  distributed: nat;
}

type storage = {
    admin: simple_admin_storage;
    assets: token_storage;
    bender: bender_storage;
    metadata : contract_metadata;
}

type return = operation list * storage

#endif