#include "tokens_lib.mligo"
#include "fees_lib.mligo"

type unwrap_erc20_parameters = 
[@layout:comb]
{
  erc_20: eth_address;
  amount: nat;
  fees: nat;
  destination: eth_address;
}

type unwrap_erc721_parameters = 
[@layout:comb]
{
  erc_721: eth_address;
  token_id: token_id;
  destination: eth_address;
}

type unwrap_entrypoints = 
  | Unwrap_erc20 of unwrap_erc20_parameters
  | Unwrap_erc721 of unwrap_erc721_parameters


let unwrap_erc20 ((p, s) : (unwrap_erc20_parameters * storage)) : return = 
  let governance = s.governance in
  let assets = s.assets in
  let fees_storage = s.fees in
  let token_address = get_fa2_token_id(p.erc_20, assets.erc20_tokens) in
  let (contract_address, token_id) = token_address in
  let mint_burn_entrypoint = token_tokens_entry_point(contract_address) in
  let min_fees = bps_of(p.amount, governance.erc20_unwrapping_fees) in
  let _ignore = check_fees_high_enough(p.fees, min_fees) in

  let burn = Tezos.transaction (Burn_tokens [{owner = Tezos.sender; token_id = token_id; amount = p.amount + p.fees}]) 0mutez mint_burn_entrypoint in
  let ops = 
    if p.fees = 0n
    then [burn]
    else [burn ; Tezos.transaction (Mint_tokens [{owner = Tezos.self_address ; token_id = token_id ; amount = p.fees}]) 0mutez mint_burn_entrypoint]
    in
  
  let new_ledger = inc_token_balance(fees_storage.tokens, Tezos.self_address, token_address, p.fees) in
  ops, { s with fees.tokens = new_ledger }

let unwrap_erc721 (p,s : unwrap_erc721_parameters * storage): return = 
    let governance = s.governance in
    let assets = s.assets in
    let fees_storage = s.fees in
    let _ignore = check_nft_fees_high_enough(Tezos.amount, governance.erc721_unwrapping_fees) in
    let contract_address = get_nft_contract(p.erc_721, assets.erc721_tokens) in
    let mint_burn_entrypoint = token_tokens_entry_point(contract_address) in
    let burn = Tezos.transaction (Burn_tokens [{owner =Tezos.sender; token_id = p.token_id; amount = 1n}]) 0mutez mint_burn_entrypoint in
    let new_ledger = inc_xtz_balance(fees_storage.xtz, Tezos.self_address, Tezos.amount) in
    [burn], {s with fees.xtz = new_ledger }

let unwrap_main (p, s : unwrap_entrypoints * storage): return = 
    match p with
    | Unwrap_erc20 p -> 
        let _ignore = fail_if_amount() in
        unwrap_erc20(p, s)
    | Unwrap_erc721 p -> unwrap_erc721(p, s)