#include "tokens.mligo"

type unwrap_erc20_parameters = {
  erc_20: eth_address;
  amount: nat;
  fees: nat;
  destination: eth_address;
}

type unwrap_erc721_parameters = {
  erc_721: eth_address;
  token_id: token_id;
  destination: eth_address;
}

type unwrap_entrypoints = 
  | Unwrap_erc20 of unwrap_erc20_parameters
  | Unwrap_erc721 of unwrap_erc721_parameters


let unwrap_erc20 ((p, g, s) : (unwrap_erc20_parameters * governance_storage * assets_storage)) : (operation list * assets_storage) = 
  let (contract_address, token_id) = get_fa2_token_id(p.erc_20, s.erc20_tokens) in
  let mint_burn_entrypoint = token_tokens_entry_point(contract_address) in
  let min_fees:nat = p.amount * g.erc20_unwrapping_fees / 10_000n in
  let ignore = check_amount_large_enough(min_fees) in
  let ignore = check_fees_high_enough(p.fees, min_fees) in
  let burn = Tezos.transaction (Burn_tokens [{owner =Tezos.sender; token_id = token_id; amount = p.amount+p.fees}]) 0mutez mint_burn_entrypoint in
  let mint = Tezos.transaction (Mint_tokens [{owner = g.fees_contract ; token_id = token_id ; amount = p.fees}]) 0mutez mint_burn_entrypoint in
  [burn; mint], s

let unwrap_erc721 (p,g,s : unwrap_erc721_parameters * governance_storage * assets_storage): (operation list * assets_storage) = 
    let ignore = check_nft_fees_high_enough(Tezos.amount, g.erc721_unwrapping_fees) in
    let contract_address = get_nft_contract(p.erc_721, s.erc721_tokens) in
    let mint_burn_entrypoint = token_tokens_entry_point(contract_address) in
    let burn = Tezos.transaction (Burn_tokens [{owner =Tezos.sender; token_id = p.token_id; amount = 1n}]) 0mutez mint_burn_entrypoint in
    let fees_ctr = fees_contract(g.fees_contract) in
    let fees = Tezos.transaction () Tezos.amount fees_ctr in
    [burn;fees], s

let unwrap_main (p, g, s : unwrap_entrypoints * governance_storage * assets_storage): (operation list * assets_storage) = 
    match p with
    | Unwrap_erc20 p -> 
        let ignore = fail_if_amount() in
        unwrap_erc20(p, g, s)
    | Unwrap_erc721 p -> unwrap_erc721(p, g, s)