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
  governance: address,
  fa2_contract: address,
  fees_contract : address,
  fees_ratio: bps,
  tokens : map(eth_address, fa2_token_id),
  mints : mints
};

type storage = {
  admin: contract_admin_storage,
  assets: assets_storage
};

type return = (list(operation), storage);

#endif