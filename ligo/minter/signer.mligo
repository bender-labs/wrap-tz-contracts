#include "signer_interface.mligo"
#include "tokens_lib.mligo"
#include "fees_lib.mligo"


let check_already_minted (tx_id, mints: eth_event_id * mints): unit = 
  let former_mint = Map.find_opt tx_id mints in
  match former_mint with 
    | Some(n) -> failwith ("TX_ALREADY_MINTED")
    | None -> unit

let mint_erc20 ((p, s) : (mint_erc20_parameters * storage)) : return = 
  let assets = s.assets in
  let governance = s.governance in
  let fees_storage = s.fees in
  let ignore = check_already_minted(p.event_id, assets.mints) in
  let (amount_to_mint, fees) : (nat * nat) = compute_fees(p.amount, governance.erc20_wrapping_fees) in
  let token_address : token_address = get_fa2_token_id(p.erc_20, assets.erc20_tokens) in
  let (fa2_contract, fa2_token_id) = token_address in
  let mintEntryPoint = token_tokens_entry_point(fa2_contract) in

  let userMint: mint_burn_tx = {owner = p.owner; token_id = fa2_token_id; amount = amount_to_mint} in
  let operations = if fees > 0n then 
    [userMint; {owner = Tezos.self_address ; token_id = fa2_token_id ; amount =fees}]
  else 
    [userMint] in
  
  let new_ledger = inc_token_balance(fees_storage.tokens, Tezos.self_address, token_address, fees) in
  let mints = Map.add p.event_id unit assets.mints in
  (([Tezos.transaction (Mint_tokens operations) 0mutez  mintEntryPoint], {s with assets.mints=mints; fees.tokens = new_ledger}))


let mint_erc721 ((p, s) : (mint_erc721_parameters * storage)) : return = 
  let assets = s.assets in
  let governance = s.governance in
  let fees_storage = s.fees in
  let ignore = check_already_minted(p.event_id, assets.mints) in
  let ignore = check_nft_fees_high_enough(Tezos.amount, governance.erc721_wrapping_fees) in
  let fa2_contract : address = get_nft_contract(p.erc_721, assets.erc721_tokens) in
  let mintEntryPoint = token_tokens_entry_point(fa2_contract) in

  let userMint : mint_burn_tx = {owner = p.owner; token_id = p.token_id; amount = 1n} in
  let new_ledger = inc_xtz_balance(fees_storage.xtz, Tezos.self_address, Tezos.amount) in
  let mints = Map.add p.event_id unit assets.mints in
  (([Tezos.transaction (Mint_tokens [userMint]) 0mutez  mintEntryPoint ], {s with assets.mints=mints; fees.xtz = new_ledger}))


let add_erc20 ((p, s): (add_erc20_parameters * assets_storage)) : assets_storage = 
  // checks contract compat
  let token_ep = token_tokens_entry_point(p.token_address.0) in
  let admin_ep = token_admin_entry_point(p.token_address.0) in
  
  let updated_tokens = Map.update p.eth_contract (Some p.token_address) s.erc20_tokens in
  {s with erc20_tokens = updated_tokens}

let add_erc721 ((p, s): (add_erc721_parameters * assets_storage)) : assets_storage = 
  // checks contract compat
  let token_ep = token_tokens_entry_point(p.token_contract) in
  let admin_ep = token_admin_entry_point(p.token_contract) in
  
  let updated_tokens = Map.update p.eth_contract (Some p.token_contract) s.erc721_tokens in
  {s with erc721_tokens = updated_tokens}

let signer_main  ((p, s):(signer_entrypoints * storage)): return = 
    match p with 
    | Mint_erc20(p) -> 
      let ignore = fail_if_amount() in
      mint_erc20(p, s)
    | Add_erc20(p) -> 
      let ignore = fail_if_amount() in
      ([]: operation list), {s with assets = add_erc20(p, s.assets)}
    | Mint_erc721 p -> mint_erc721(p, s)
    | Add_erc721 p -> 
      let ignore = fail_if_amount() in
      ([]: operation list), {s with assets = add_erc721(p, s.assets)}
    
