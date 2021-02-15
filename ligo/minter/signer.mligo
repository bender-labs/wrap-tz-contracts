#include "tokens.mligo"
#include "ethereum.mligo"


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


let mint_erc20 ((p, f, s) : (mint_erc20_parameters * governance_storage * assets_storage)) : (operation list) * assets_storage = 
  let ignore = check_already_minted(p.event_id, s.mints) in
  let (amount_to_mint, fees) : (nat * nat) = compute_fees(p.amount, f.erc20_wrapping_fees) in
  let (fa2_contract, fa2_token_id) : token_address = get_fa2_token_id(p.erc_20, s.erc20_tokens) in
  let mintEntryPoint = token_tokens_entry_point(fa2_contract) in

  let userMint:mint_burn_tx = {owner = p.owner; token_id = fa2_token_id; amount = amount_to_mint} in
  let operations = if fees > 0n then 
    [userMint; {owner = f.fees_contract ; token_id = fa2_token_id ; amount =fees}]
  else 
    [userMint] in
  
  let mints = Map.add p.event_id unit s.mints in
  (([Tezos.transaction (Mint_tokens operations) 0mutez  mintEntryPoint], {s with mints=mints}))


let mint_erc721 ((p, f, s) : (mint_erc721_parameters * governance_storage * assets_storage)) : (operation list) * assets_storage = 
  let ignore = check_already_minted(p.event_id, s.mints) in
  let ignore = check_nft_fees_high_enough(Tezos.amount, f.erc721_wrapping_fees) in
  let fa2_contract : address = get_nft_contract(p.erc_721, s.erc721_tokens) in
  let mintEntryPoint = token_tokens_entry_point(fa2_contract) in

  let userMint : mint_burn_tx = {owner = p.owner; token_id = p.token_id; amount = 1n} in
  let fees_ctr = fees_contract(f.fees_contract) in
  let fees = Tezos.transaction () Tezos.amount fees_ctr in
  let mints = Map.add p.event_id unit s.mints in
  (([Tezos.transaction (Mint_tokens [userMint]) 0mutez  mintEntryPoint ; fees], {s with mints=mints}))


let add_erc20 ((p, s): (add_erc20_parameters * assets_storage)) : ((operation list) * assets_storage) = 
  // checks contract compat
  let token_ep = token_tokens_entry_point(p.token_address.0) in
  let admin_ep = token_admin_entry_point(p.token_address.0) in
  
  let updated_tokens = Map.update p.eth_contract (Some p.token_address) s.erc20_tokens in
  (([]:operation list), {s with erc20_tokens = updated_tokens})

let add_erc721 ((p, s): (add_erc721_parameters * assets_storage)) : ((operation list) * assets_storage) = 
  // checks contract compat
  let token_ep = token_tokens_entry_point(p.token_contract) in
  let admin_ep = token_admin_entry_point(p.token_contract) in
  
  let updated_tokens = Map.update p.eth_contract (Some p.token_contract) s.erc721_tokens in
  ([]:operation list), {s with erc721_tokens = updated_tokens}

let signer_main  ((p, g, s):(signer_entrypoints * governance_storage * assets_storage)): ((operation list) * assets_storage) = 
    match p with 
    | Mint_erc20(p) -> 
      let ignore = fail_if_amount() in
      mint_erc20(p, g, s)
    | Add_erc20(p) -> 
      let ignore = fail_if_amount() in
      add_erc20(p, s)
    | Mint_erc721 p -> mint_erc721(p, g, s)
    | Add_erc721 p -> 
      let ignore = fail_if_amount() in
      add_erc721(p, s)
    