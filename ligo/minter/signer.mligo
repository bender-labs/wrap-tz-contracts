#include "tokens.mligo"
#include "ethereum.mligo"


type mint_fungible_parameters = 
[@layout:comb]
{
  erc_20: eth_address;
  event_id: eth_event_id;
  owner: address;
  amount: nat;
}

type add_fungible_parameters =
[@layout:comb]
{
  eth_contract: eth_address;
  token_address: token_address;
}

type add_nft_parameters =
[@layout:comb]
{
  eth_contract: eth_address;
  token_contract: address;
}

type mint_nft_parameters = 
[@layout:comb]
{
  erc_721: eth_address;
  event_id: eth_event_id;
  owner: address;
  token_id: nat;
}

type signer_entrypoints = 
| Mint_fungible_token of mint_fungible_parameters
| Add_fungible_token of add_fungible_parameters
| Mint_nft of mint_nft_parameters
| Add_nft of add_nft_parameters


let check_already_minted (tx_id, mints: eth_event_id * mints): unit = 
  let former_mint = Map.find_opt tx_id mints in
  match former_mint with 
    | Some(n) -> failwith ("TX_ALREADY_MINTED")
    | None -> unit

let compute_fees (value, bps: nat * bps):( nat * nat ) = 
  let fees:nat = value * bps / 10_000n in
  let amount_to_mint : nat = (match Michelson.is_nat(value - fees) with
    | Some(n) -> n 
    | None -> (failwith("BAD_FEES"):nat)) in
  (amount_to_mint, fees)


let mint ((p, f, s) : (mint_fungible_parameters * governance_storage * assets_storage)) : (operation list) * assets_storage = 
  let ignore = check_already_minted(p.event_id, s.mints) in
  let (amount_to_mint, fees) : (nat * nat) = compute_fees(p.amount, f.wrapping_fees) in
  let (fa2_contract, fa2_token_id) : token_address = get_fa2_token_id(p.erc_20, s.fungible_tokens) in
  let mintEntryPoint = token_tokens_entry_point(fa2_contract) in

  let userMint:mint_burn_tx = {owner = p.owner; token_id = fa2_token_id; amount = amount_to_mint} in
  let operations:mint_burn_tokens_param = if fees > 0n then 
    [userMint; {owner = f.fees_contract ; token_id = fa2_token_id ; amount =fees}]
  else 
    [userMint] in
  
  let mints = Map.add p.event_id unit s.mints in
  (([Tezos.transaction (Mint_tokens operations) 0mutez  mintEntryPoint], {s with mints=mints}))


let mint_nft ((p, f, s) : (mint_nft_parameters * governance_storage * assets_storage)) : (operation list) * assets_storage = 
  let ignore = check_already_minted(p.event_id, s.mints) in
  let fa2_contract : address = get_nft_contract(p.erc_721, s.nfts) in
  let mintEntryPoint = token_tokens_entry_point(fa2_contract) in

  let userMint:mint_burn_tx = {owner = p.owner; token_id = p.token_id; amount = 1n} in
  let mints = Map.add p.event_id unit s.mints in
  (([Tezos.transaction (Mint_tokens [userMint]) 0mutez  mintEntryPoint], {s with mints=mints}))


let add_token ((p, s): (add_fungible_parameters * assets_storage)) : ((operation list) * assets_storage) = 
  // checks contract compat
  let token_ep = token_tokens_entry_point(p.token_address.0) in
  let admin_ep = token_admin_entry_point(p.token_address.0) in
  
  let updated_tokens = Map.update p.eth_contract (Some p.token_address) s.fungible_tokens in
  (([]:operation list), {s with fungible_tokens = updated_tokens})


let signer_main  ((p, g, s):(signer_entrypoints * governance_storage * assets_storage)): ((operation list) * assets_storage) = 
    match p with 
    | Mint_fungible_token(p) -> mint(p, g, s)
    | Add_fungible_token(p) -> add_token(p, s)
    | Mint_nft p -> mint_nft(p, g, s)
    | Add_nft -> (failwith "not implemented": ((operation list) * assets_storage))
    
