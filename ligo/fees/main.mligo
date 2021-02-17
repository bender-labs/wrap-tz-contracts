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


let inc_pending_balance (balances, tx : balance_sheet * transfer_destination_descriptor)
    : balance_sheet =
  let key = (Tezos.sender, tx.token_id) in
  let info_opt = Map.find_opt key balances.tokens in
  let new_balance = 
    match info_opt with
    | None -> tx.amount
    | Some info -> tx.amount + info
    in
  let tokens = Map.update key (Some new_balance) balances.tokens in
  {balances with tokens = tokens}

let tokens_received (p, s: transfer_descriptor_param * storage): storage = 
    let new_state = 
        List.fold
        (fun (s, td : balance_sheet * transfer_descriptor) ->
            List.fold 
                (fun (s, tx : balance_sheet * transfer_destination_descriptor) ->
                match tx.to_ with
                | None -> s
                | Some to_ ->
                    if to_ <> Tezos.self_address
                    then s
                    else inc_pending_balance (s, tx)
                ) td.txs s
        ) p.batch s.ledger.to_distribute
        in
    {s with ledger.to_distribute = new_state}    


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
    | Tokens_received p -> 
        if Set.mem Tezos.sender s.minter.listed_tokens then
            ([]:operation list), tokens_received (p, s)
        else
            (failwith "TOKEN_NOT_LISTED": contract_return)
        
    | Claim p -> ([]:operation list), s
