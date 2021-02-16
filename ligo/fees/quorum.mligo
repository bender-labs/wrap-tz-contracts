#include "quorum_interface.mligo"
#include "storage.mligo"


let balance_sheet_or_default (k,ledger : address * ((address, balance_sheet) map)): balance_sheet =
    match Map.find_opt k ledger with
    | Some v -> v
    | None -> {xtz=0tez; tokens=(Map.empty: (token_address, nat) map)}

let tez_amount (quantity, share: tez*nat):tez =
    let r:tez = quantity * share in
    match ediv r 100n with
    | Some e ->
        let (q, r) = e in
        q
    | None -> 0tez

type share_per_address = address * nat

// let distribute_token (ledger, token, targets : ((address, balance_sheet)) map * token_address * address set): ((address, balance_sheet) map) *  nat =
 //   let d ()

let distribute_tez (s, ledger: (share_per_address list)*ledger_storage ):ledger_storage =
    let total = ledger.to_distribute.xtz in
    let apply : ledger_storage * share_per_address -> ledger_storage =
        (fun (ledger, share : ledger_storage * share_per_address) -> 
            let (receiver_address, percent) = share in
            let tez_fees = tez_amount(total, percent) in
            let receiver = balance_sheet_or_default(receiver_address, ledger.distribution) in
            let receiver = {receiver with xtz = receiver.xtz + tez_fees} in
            let distribution = Map.update receiver_address (Some receiver) ledger.distribution in        
            let to_distribute = {ledger.to_distribute with xtz = ledger.to_distribute.xtz - tez_fees} in
            {ledger with to_distribute = to_distribute; distribution = distribution}
        ) in
        
    List.fold apply s ledger


let key_or_registered_address (k, s : key_hash * (key_hash, address) map) : address = 
    match Map.find_opt k s with
    | Some v -> v
    | None -> Tezos.address (Tezos.implicit_account k)

let distribute (p, s : distribute_param * storage):ledger_storage = 
    let ledger = s.ledger in
    let governance = s.governance in
    let quorum = s.quorum in
    let signers_count = List.length p.signers in
    let shares = [(governance.dev_pool, governance.dev_fees);(governance.staking, governance.staking_fees)] in
    let shares: share_per_address list =
        List.fold 
        (fun (acc, k : share_per_address list * key_hash) -> 
            (key_or_registered_address(k, quorum.signers), governance.signers_fees / signers_count ):: acc
        ) 
        p.signers
        shares
        in
    
    distribute_tez(shares, ledger)
    
    

let quorum_main (p, s: quorum_entry_points * storage) : contract_return = 
    match p with
    | Set_quorum_contract p -> (failwith "NOT_IMPLEMENTED" : contract_return)
    | Set_signer_payment_address p -> (failwith "NOT_IMPLEMENTED" : contract_return)
    | Distribute p -> 
        ([]: operation list), {s with ledger = distribute(p, s)}