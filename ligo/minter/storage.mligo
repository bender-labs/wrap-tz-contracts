#if !INTERFACE
#define INTERFACE

#include "ethereum_lib.mligo"
#include "types.mligo"


type contract_admin_storage = {
    administrator: address;
    pending_admin: address option;
    signer: address;
    oracle: address;
    paused: bool;
}

type mints = (eth_event_id, unit) big_map

type assets_storage = {
  erc20_tokens: (eth_address, token_address) map;
  erc721_tokens: (eth_address, address) map;
  mints: mints;
}

type fees_share = 
[@layout:comb]
{
  dev_pool: nat;
  signers: nat;
  staking: nat;
}

type governance_storage = {
  contract: address;
  staking: address;
  dev_pool: address;
  erc20_wrapping_fees: bps;
  erc20_unwrapping_fees: bps;
  erc721_wrapping_fees: tez;
  erc721_unwrapping_fees: tez;
  fees_share: fees_share;
}

type token_ledger = ((address * token_address), nat) big_map

type xtz_ledger = (address, tez) big_map

type fees_storage = {
    signers: (key_hash, address) map;
    tokens: token_ledger;
    xtz: xtz_ledger;
}

type storage = {
  admin: contract_admin_storage;
  assets: assets_storage;
  governance: governance_storage;
  fees: fees_storage;
  metadata:metadata;
}

type return = (operation list) * storage

#endif