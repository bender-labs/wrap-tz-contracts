#include "ethereum_lib.mligo"
#include "types.mligo"

type mint_erc20_parameters = 
[@layout:comb]
{
  erc_20: eth_address;
  event_id: eth_event_id;
  owner: address;
  amount: nat;
}

type add_erc20_parameters =
[@layout:comb]
{
  eth_contract: eth_address;
  token_address: token_address;
}

type add_erc721_parameters =
[@layout:comb]
{
  eth_contract: eth_address;
  token_contract: address;
}

type mint_erc721_parameters = 
[@layout:comb]
{
  erc_721: eth_address;
  event_id: eth_event_id;
  owner: address;
  token_id: nat;
}

type signer_entrypoints = 
| Mint_erc20 of mint_erc20_parameters
| Add_erc20 of add_erc20_parameters
| Mint_erc721 of mint_erc721_parameters
| Add_erc721 of add_erc721_parameters