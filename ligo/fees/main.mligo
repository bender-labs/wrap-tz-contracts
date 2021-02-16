#include "../fa2/common/fa2_interface.mligo"
#include "minter.mligo"
#include "quorum.mligo"
#include "governance.mligo"


let fail_if_not_quorum (p: quorum_storage) = 
    if Tezos.sender <> p.contract 
    then failwith "NOT_QUORUM"

let fail_if_not_goverance (p: governance_storage) = 
    if Tezos.sender <> p.contract 
    then failwith "NOT_GOVERNANCE"

let fail_if_not_minter (p: minter_storage) = 
    if Tezos.sender <> p.contract
    then failwith "NOT_SIGNER"

type entry_points = 
| Default
| Quorum of quorum_entry_points
| Governance of governance_entry_points
| Minter of minter_entry_points
| Tokens_received of transfer_descriptor_param
| Claim of token_list


let main (p, s : entry_points * storage) : contract_return = 
    match p with
    | Default ->
        let xtz_amount = s.ledger.to_distribute.xtz + Tezos.amount in
        let new_ledger = {s.ledger with to_distribute.xtz = xtz_amount} in
        ([]: operation list), {s with ledger = new_ledger}
    | Quorum p -> 
        let ignore = fail_if_not_quorum(s.quorum) in
        quorum_main(p, s)
    | Governance p -> 
        let ignore = fail_if_not_goverance s.governance in
        let (ops, new_state) = governance_main(p, s.governance) in
        ops, { s with governance = new_state }
    | Minter p ->
        let ignore = fail_if_not_minter(s.minter) in
        let (ops, new_state) = minter_main(p, s.minter) in
        ops, { s with minter = new_state }
    | Tokens_received -> ([]:operation list), s
    | Claim p -> ([]:operation list), s
