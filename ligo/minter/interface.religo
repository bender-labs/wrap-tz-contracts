#if !INTERFACE
#define INTERFACE

#include "ethereum.religo"

type bps = nat

type metadata = big_map(string, bytes);

type contract_admin_storage = {
    administrator: address,
    signer: address,
    paused: bool
};

type mints = big_map(eth_event_id, unit);

type token_address = (address, fa2_token_id);


type assets_storage = {
  tokens : map(eth_address, token_address),
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
  governance: governance_storage,
  metadata:metadata
};

type return = (list(operation), storage);

#endif