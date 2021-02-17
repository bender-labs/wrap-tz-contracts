#include "quorum_interface.mligo"
#include "storage.mligo"


let balance_sheet_or_default (k,ledger : address * ((address, balance_sheet) big_map)): balance_sheet =
    match Big_map.find_opt k ledger with
    | Some v -> v
    | None -> {xtz=0tez; tokens=(Map.empty: (token_address, nat) map)}

let tez_share (quantity, share: tez*nat) : tez =
    let r:tez = quantity * share in
    match ediv r 100n with
    | Some e ->
        let (q, r) = e in
        q
    | None -> 0tez

let token_share (quantity, share: nat*nat) : nat =
    let r:nat = quantity * share in
    match ediv r 100n with
    | Some e ->
        let (q, r) = e in
        q
    | None -> 0n

type share_per_address = address * nat

let token_amount_in (b, t : balance_sheet * token_address): nat = 
    match Map.find_opt t b.tokens with
    | Some n -> n
    | None -> 0n

let distribute_token (s, t, ledger: (share_per_address list) * token_address * ledger_storage ) : ledger_storage =
    match Map.find_opt t ledger.to_distribute.tokens with
    | None -> ledger
    | Some total -> 
        let apply : (nat * ((address, balance_sheet) big_map)) * share_per_address -> (nat * ((address, balance_sheet) big_map)) =
            (fun (acc, share : (nat * (address, balance_sheet) big_map) * share_per_address) -> 
                let (distributed, distribution) = acc in
                let (receiver_address, percent) = share in
                let token_fees = token_share(total, percent) in
                let receiver = balance_sheet_or_default(receiver_address, distribution) in
                let current_balance = token_amount_in(receiver, t) in
                let receiver = {receiver with tokens = (Map.update t (Some (current_balance + token_fees)) receiver.tokens) } in
                let new_distribution = Big_map.update receiver_address (Some receiver) distribution in        
                (distributed + token_fees, new_distribution)
            ) in
            
        let (distributed, new_distribution) = List.fold apply s (0n, ledger.distribution) in
        let remaining = 
            match is_nat (total - distributed) with 
            | Some v -> v 
            | None -> 0n
            in
        let to_distribute = Map.update t (Some remaining) ledger.to_distribute.tokens in
        {ledger with to_distribute.tokens = to_distribute; distribution = new_distribution}

let distribute_tokens (s, t, ledger: (share_per_address list) * (token_address list) * ledger_storage ) : ledger_storage =
    List.fold
        (fun (ledger,t:ledger_storage * token_address) -> distribute_token(s, t, ledger))
        t
        ledger


let distribute_tez (s, ledger : (share_per_address list) * ledger_storage ) : ledger_storage =
    let total = ledger.to_distribute.xtz in
    let apply : (tez * ((address, balance_sheet) big_map)) * share_per_address -> (tez * ((address, balance_sheet) big_map)) =
        (fun (acc, share : (tez * ((address, balance_sheet) big_map)) * share_per_address) -> 
            let (distributed, distribution) = acc in
            let (receiver_address, percent) = share in
            let tez_fees = tez_share(total, percent) in
            let receiver = balance_sheet_or_default(receiver_address, distribution) in
            let receiver = {receiver with xtz = receiver.xtz + tez_fees} in
            let distribution = Big_map.update receiver_address (Some receiver) distribution in        
            (distributed+tez_fees, distribution)
            
        ) in
    let (distributed, new_distribution) = List.fold apply s (0tez, ledger.distribution) in    
    let remaining = if (total - distributed) >= 0tez then (total - distributed) else 0tez in    
    {ledger with to_distribute.xtz = remaining; distribution = new_distribution}
    


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
    
    let new_storage = distribute_tez(shares, ledger) in
    distribute_tokens(shares, p.tokens, new_storage)
    
    

let quorum_main (p, s: quorum_entry_points * storage) : contract_return = 
    match p with
    | Set_quorum_contract p ->
        ([]:operation list), { s with quorum.contract = p }
    | Set_signer_payment_address p -> 
        let new_quorum = Map.update p.signer (Some p.payment_address) s.quorum.signers in
        ([]: operation list), {s with quorum.signers = new_quorum}
    | Distribute p -> 
        ([]: operation list), {s with ledger = distribute(p, s)}