#include "tokens.mligo"

type unwrap_fungible_parameters = {
  erc_20: eth_address;
  amount: nat;
  fees: nat;
  destination: eth_address;
}

type unwrap_nft_parameters = {
  erc_721: eth_address;
  token_id: token_id;
  destination: eth_address;
}

type unwrap_entrypoints = 
  | Unwrap_fungible of unwrap_fungible_parameters
  | Unwrap_nft of unwrap_nft_parameters


let unwrap_fungible ((p, g, s) : (unwrap_fungible_parameters * governance_storage * assets_storage)) : (operation list * assets_storage) = 
  let (contract_address, token_id) = get_fa2_token_id(p.erc_20, s.fungible_tokens) in
  let mint_burn_entrypoint = token_tokens_entry_point(contract_address) in
  let min_fees:nat = p.amount * g.unwrapping_fees / 10_000n in
  let ignore = check_amount_large_enough(min_fees) in
  let ignore = check_fees_high_enough(p.fees, min_fees) in
  let burn = Tezos.transaction (Burn_tokens [{owner =Tezos.sender; token_id = token_id; amount = p.amount+p.fees}]) 0mutez mint_burn_entrypoint in
  let mint = Tezos.transaction (Mint_tokens [{owner = g.fees_contract ; token_id = token_id ; amount = p.fees}]) 0mutez mint_burn_entrypoint in
  [burn; mint], s

let unwrap_nft (p,g,s : unwrap_nft_parameters * governance_storage * assets_storage): (operation list * assets_storage) = 
    let ignore = check_nft_fees_high_enough(Tezos.amount, g.nft_unwrapping_fees) in
    let contract_address = get_nft_contract(p.erc_721, s.nfts) in
    let mint_burn_entrypoint = token_tokens_entry_point(contract_address) in
    let burn = Tezos.transaction (Burn_tokens [{owner =Tezos.sender; token_id = p.token_id; amount = 1n}]) 0mutez mint_burn_entrypoint in
    let fees_ctr = fees_contract(g.fees_contract) in
    let fees = Tezos.transaction () Tezos.amount fees_ctr in
    [burn;fees], s

let unwrap_main (p, g, s : unwrap_entrypoints * governance_storage * assets_storage): (operation list * assets_storage) = 
    match p with
    | Unwrap_fungible p -> 
        let ignore = fail_if_amount() in
        unwrap_fungible(p, g, s)
    | Unwrap_nft p -> unwrap_nft(p, g, s)