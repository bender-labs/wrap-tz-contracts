#if !INTERFACE
#define INTERFACE

#include "ethereum.mligo"

type bps = nat

type metadata = (string, bytes) big_map

type contract_admin_storage = {
    administrator: address;
    signer: address;
    paused: bool;
}

type mints = (eth_event_id, unit) big_map

type token_address = address * token_id

type assets_storage = {
  erc20_tokens: (eth_address, token_address) map;
  erc721_tokens: (eth_address, address) map;
  mints: mints;
}

type governance_storage = {
  contract: address;
  erc20_wrapping_fees: bps;
  erc20_unwrapping_fees: bps;
  erc721_wrapping_fees: tez;
  erc721_unwrapping_fees: tez;
  fees_contract: address;
}

type storage = {
  admin: contract_admin_storage;
  assets: assets_storage;
  governance: governance_storage;
  metadata:metadata;
}

type return = (operation list) * storage

#endif