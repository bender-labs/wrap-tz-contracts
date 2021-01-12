#if !INTERFACE
#define INTERFACE

#include "ethereum.religo"

type bps = nat

type contract_admin_storage = {
    administrator: address,
    signer: address,
    paused: bool
};

type mints = big_map(eth_tx_id, unit);


type assets_storage = {
  fa2_contract: address,
  tokens : map(eth_address, fa2_token_id),
  mints : mints
};

type governance_storage = {
  contract: address,
  wrapping_fees: bps,
  unwrapping_fees: bps,
  fees_contract: address
};

type storage = {
  admin: contract_admin_storage,
  assets: assets_storage,
  governance: governance_storage
};

type return = (list(operation), storage);

#endif