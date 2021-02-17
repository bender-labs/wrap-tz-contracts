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
| Withdraw_tokens of token_list
| Withdraw_xtz


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

let transfer_xtz (addr, value : address * tez) : operation =
    match (Tezos.get_contract_opt addr : unit contract option) with
    | Some c -> Tezos.transaction unit value c
    | None -> (failwith "NOT_PAYABLE":operation)


let withdraw_xtz (s: ledger_storage) : (operation list) * ledger_storage=
    let entry = Big_map.find_opt Tezos.sender s.distribution in
    match entry with 
    | None -> ([]:operation list), s
    | Some b ->
        if b.xtz > 0tez then
            let op = transfer_xtz(Tezos.sender, b.xtz) in 
            let new_b = {b with xtz = 0tez} in
            let new_d = Big_map.update Tezos.sender (Some new_b) s.distribution in
            [op], { s with distribution = new_d }
        else
            ([]:operation list), s

let withdraw_tokens(p, s : token_list * ledger_storage) : (operation list) * ledger_storage = 
    ([] : operation list), s

let main (p, s : entry_points * storage) : contract_return = 
    match p with
    | Default ->
        let xtz_amount = s.ledger.to_distribute.xtz + Tezos.amount in
        let new_ledger = { s.ledger with to_distribute.xtz = xtz_amount } in
        ([]: operation list), {s with ledger = new_ledger}
    | Withdraw_xtz  -> 
        let (ops, updated_ledger) = withdraw_xtz(s.ledger) in
        ops, {s with ledger=updated_ledger}
    | Withdraw_tokens p -> 
        let (ops, updated_ledger) = withdraw_tokens(p, s.ledger) in
        ops, {s with ledger=updated_ledger}
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
