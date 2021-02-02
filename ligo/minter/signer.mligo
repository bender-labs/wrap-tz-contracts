#include "tokens.mligo"
#include "ethereum.mligo"

type mint_parameters = {
  token_id: eth_address;
  event_id: eth_event_id;
  owner: address;
  amount: nat;
}

type add_token_parameters = {
  eth_contract: eth_address;
  token_address: token_address;
}

type signer_entrypoints = 
| Mint_token of mint_parameters
| Add_token of add_token_parameters


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


let mint ((p, f, s) : (mint_parameters * governance_storage * assets_storage)) : (operation list) * assets_storage = 
  let ignore = check_already_minted(p.event_id, s.mints) in
  let (amount_to_mint, fees) : (nat * nat) = compute_fees(p.amount, f.wrapping_fees) in
  let (fa2_contract, fa2_token_id) : token_address = get_fa2_token_id(p.token_id, s.tokens) in
  let mintEntryPoint = token_tokens_entry_point(fa2_contract) in

  let userMint:mint_burn_tx = {owner = p.owner; token_id = fa2_token_id; amount = amount_to_mint} in
  let operations:mint_burn_tokens_param = if fees > 0n then 
    [userMint; {owner = f.fees_contract ; token_id = fa2_token_id ; amount =fees}]
  else 
    [userMint] in
  
  let mints = Map.add p.event_id unit s.mints in
  (([Tezos.transaction (Mint_tokens operations) 0mutez  mintEntryPoint], {s with mints=mints}))


let add_token ((p, s): (add_token_parameters * assets_storage)) : ((operation list) * assets_storage) = 
  // checks contract compat
  let token_ep = token_tokens_entry_point(p.token_address.0) in
  let admin_ep = token_admin_entry_point(p.token_address.0) in
  
  let updated_tokens = Map.update p.eth_contract (Some p.token_address) s.tokens in
  (([]:operation list), {s with tokens = updated_tokens})


let signer_main  ((p, g, s):(signer_entrypoints * governance_storage * assets_storage)): ((operation list) * assets_storage) = 
    match p with 
    | Mint_token(p) -> mint(p, g, s)
    | Add_token(p) -> add_token(p, s)
    
