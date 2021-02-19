#if !INTERFACE
#define INTERFACE

#include "ethereum_lib.mligo"
#include "types.mligo"


type contract_admin_storage = {
    administrator: address;
    signer: address;
    paused: bool;
}


type assets_storage = {
  erc20_tokens: (eth_address, token_address) map;
  erc721_tokens: (eth_address, address) map;
  mints: mints;
}

type fees_share = {
  dev_pool: nat;
  signers: nat;
  staking: nat;
}

type governance_storage = {
  contract: address;
  erc20_wrapping_fees: bps;
  erc20_unwrapping_fees: bps;
  erc721_wrapping_fees: tez;
  erc721_unwrapping_fees: tez;
  fees_share: fees_share;
}

type balance_sheet = {
    xtz: tez;
    tokens: (token_address, nat) map;
}

type fees_storage = {
    signers: (key_hash, address) map;
    pending: balance_sheet;
    distributed: (address, balance_sheet) big_map;
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