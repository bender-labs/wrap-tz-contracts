#include "../fa2/common/fa2_interface.mligo"
#include "storage.mligo"
#include "contract_admin.mligo"
#include "governance.mligo"
#include "signer.mligo"
#include "assets_admin.mligo"
#include "unwrap.mligo"


type entry_points = 
  | Signer of signer_entrypoints
  | Unwrap of unwrap_entrypoints
  | Contract_admin of contract_admin_entrypoints
  | Governance of governance_entrypoints
  | Assets_admin of assets_admin_entrypoints

let fail_if_paused (s:contract_admin_storage) =
  if s.paused then failwith("CONTRACT_PAUSED")  

let main ((p, s):(entry_points * storage)) : return = 
  match p with 
  | Signer(n) ->
    let ignore = fail_if_not_signer(s.admin) in
    let ignore = fail_if_paused(s.admin) in
    let (ops, new_storage) = signer_main(n,s) in
    ops, new_storage
  | Unwrap(n) ->
    let ignore = fail_if_paused(s.admin) in
    unwrap_main(n, s)
  | Contract_admin(n) ->
    let ignore = fail_if_amount() in
    let ignore = fail_if_not_admin(s.admin) in
    let (ops, new_storage) = contract_admin_main(n, s.admin) in
    ops, {s with admin = new_storage}
  | Governance(n) ->
    let ignore = fail_if_amount() in
    let ignore = fail_if_not_governance(s.governance) in
    let (ops, new_storage) = governance_main(n, s.governance) in
    ops, {s with governance = new_storage}
  | Assets_admin(n) -> 
    let ignore = fail_if_amount() in
    let ignore = fail_if_not_admin(s.admin) in
    let (ops, new_storage) = assets_admin_main(n, s.assets) in
    ops, {s with assets = new_storage}
