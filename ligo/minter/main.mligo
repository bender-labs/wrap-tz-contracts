(*
  Wrap protocol Minter contract.
  The contract is splitted by responsability area, this file is the just the main router.
  To learn more about this contrat, go to https://github.com/bender-labs/wrap-tz-contracts/wiki/Minter
*)

#include "../fa2/common/fa2_interface.mligo"
#include "storage.mligo"
#include "contract_admin.mligo"
#include "governance.mligo"
#include "signer.mligo"
#include "unwrap.mligo"
#include "fees.mligo"
#include "oracle.mligo"
#include "signer_ops.mligo"


type entry_points = 
  | Signer of signer_entrypoints
  | Unwrap of unwrap_entrypoints
  | Contract_admin of contract_admin_entrypoints
  | Governance of governance_entrypoints
  | Fees of withdrawal_entrypoint
  | Oracle of oracle_entrypoint
  | Signer_ops of signer_ops_entrypoint

let fail_if_paused (s:contract_admin_storage) =
  if s.paused then failwith("CONTRACT_PAUSED")  

let main ((p, s):(entry_points * storage)) : return = 
  match p with 
  | Signer(n) ->
    let _ignore = fail_if_not_signer(s.admin) in
    let _ignore = fail_if_paused(s.admin) in
    signer_main(n,s)
  | Unwrap(n) ->
    let _ignore = fail_if_paused(s.admin) in
    unwrap_main(n, s)
  | Contract_admin(n) ->
    let _ignore = fail_if_amount() in
    let (ops, new_storage) = contract_admin_main(n, s.admin) in
    ops, {s with admin = new_storage}
  | Governance(n) ->
    let _ignore = fail_if_amount() in
    let _ignore = fail_if_not_governance(s.governance) in
    let (ops, new_storage) = governance_main(n, s.governance) in
    ops, {s with governance = new_storage}
  | Fees(p)->
    let _ignore = fail_if_amount() in
    fees_main(p, s)
  | Oracle(p)->
    let _ignore = fail_if_amount() in
    let _ignore = fail_if_not_oracle(s.admin) in
    oracle_main(p, s)
  | Signer_ops(p) -> 
    let _ignore = fail_if_amount() in
    let _ignore = fail_if_not_signer(s.admin) in
    signer_ops_main(p, s)
