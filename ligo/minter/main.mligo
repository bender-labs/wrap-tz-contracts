#include "../fa2/common/fa2_interface.mligo"
#include "interface.mligo"
#include "contract_admin.mligo"
#include "governance.mligo"
#include "signer.mligo"
#include "assets_admin.mligo"


type unwrap_parameters = {
  token_id: eth_address;
  amount: nat;
  fees: nat;
  destination: eth_address;
}

type entry_points = 
  | Signer of signer_entrypoints
  | Unwrap of unwrap_parameters
  | Contract_admin of contract_admin_entrypoints
  | Governance of governance_entrypoints
  | Assets_admin of assets_admin_entrypoints


let check_fees_high_enough ((v, min):(nat * nat)) =
  if v < min then failwith("FEES_TOO_LOW")
  

let check_amount_large_enough (v:nat) =
  if v < 1n then failwith("AMOUNT_TOO_SMALL")

let unwrap ((p, g, s) : (unwrap_parameters * governance_storage * assets_storage)) : (operation list * assets_storage) = 
  let (contract_address, token_id) = get_fa2_token_id(p.token_id, s.fungible_tokens) in
  let mint_burn_entrypoint = token_tokens_entry_point(contract_address) in
  let min_fees:nat = p.amount * g.unwrapping_fees / 10_000n in
  let ignore = check_amount_large_enough(min_fees) in
  let ignore = check_fees_high_enough(p.fees, min_fees) in
  let burn = Tezos.transaction (Burn_tokens [{owner =Tezos.sender; token_id = token_id; amount = p.amount+p.fees}]) 0mutez mint_burn_entrypoint in
  let mint = Tezos.transaction (Mint_tokens [{owner = g.fees_contract ; token_id = token_id ; amount = p.fees}]) 0mutez mint_burn_entrypoint in
  (([burn; mint]), s)


let fail_if_paused (s:contract_admin_storage) =
  if s.paused then failwith("CONTRACT_PAUSED")

let fail_if_amount (v:unit) =
  if Tezos.amount > 0tez then failwith("FORBIDDEN_XTZ")
  

let main ((p, s):(entry_points * storage)) : return = 
  let ignore = fail_if_amount() in
  match p with 
  | Signer(n) ->
    let ignore = fail_if_not_signer(s.admin) in
    let ignore = fail_if_paused(s.admin) in
    let (ops, new_storage) = signer_main(n,s.governance, s.assets) in
    (ops, {s with assets = new_storage})
    
  | Unwrap(n) ->
    let ignore = fail_if_paused(s.admin) in
    let (ops, new_storage) = unwrap(n, s.governance, s.assets) in
    (ops, {s with assets = new_storage})
  | Contract_admin(n) ->
    let ignore = fail_if_not_admin(s.admin) in
    let (ops, new_storage) = contract_admin_main(n, s.admin) in
    ((ops:operation list), {s with admin = new_storage})
    
  | Governance(n) ->
    let ignore = fail_if_not_governance(s.governance) in
    let (ops, new_storage) = governance_main(n, s.governance) in
    (ops, {s with governance = new_storage})
  
  | Assets_admin(n) -> 
    let ignore = fail_if_not_admin(s.admin) in
    let (ops, new_storage) = assets_admin_main(n, s.assets) in
    (ops, {s with assets = new_storage})
