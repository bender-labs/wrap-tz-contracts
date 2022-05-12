#include "oracle_interface.mligo"
#include "storage.mligo"



let balance_sheet_or_default (k,token, ledger : address * token_address * token_ledger): nat =
    match Big_map.find_opt (k,token) ledger with
    | Some v -> v
    | None -> 0n

let tez_share (quantity, share: tez*nat) : tez =
    let r:tez = quantity * share in
    match ediv r 100n with
    | Some e ->
        let (q, _r) = e in
        q
    | None -> 0tez

let token_share (quantity, share: nat*nat) : nat =
    let r:nat = quantity * share in
    match ediv r 100n with
    | Some e ->
        let (q, _r) = e in
        q
    | None -> 0n

type share_per_address = address * nat


let token_for_share (shares, token_address, ledger: (share_per_address list) * token_address * token_ledger ) : token_ledger =
    let total = token_balance(ledger, Tezos.self_address, token_address) in
    if total = 0n then
        ledger
    else
        let apply : (nat * token_ledger) * share_per_address -> (nat * token_ledger) =
            (fun (acc, share : (nat * token_ledger) * share_per_address) -> 
                let (distributed, distribution) = acc in
                let (receiver_address, percent) = share in
                let token_fees = token_share(total, percent) in
                let updated_ledger = inc_token_balance(distribution, receiver_address, token_address, token_fees) in
                (distributed + token_fees, updated_ledger)
            ) in
            
        let (distributed, new_distribution) = List.fold apply shares (0n, ledger) in
        let remaining = 
            match is_nat (total - distributed) with 
            | Some v -> v 
            | None -> (failwith "DISTRIBUTION_FAILED" : nat)
            in
        Big_map.update (Tezos.self_address, token_address) (Some remaining) new_distribution
        

let tokens_for_share (s, tokens, ledger: (share_per_address list) * (token_address list) * token_ledger ) : token_ledger =
    List.fold
        (fun (l, t : token_ledger * token_address) -> token_for_share(s, t, l))
        tokens
        ledger
    
let key_or_registered_address (k, s : key_hash * (key_hash, address) map) : address = 
    match Map.find_opt k s with
    | Some v -> v
    | None -> Tezos.address (Tezos.implicit_account k)

let shares (p, signers, governance : key_hash list * (key_hash, address) map *  governance_storage): share_per_address list = 
    let signers_count = List.length p in
    let other_shares = [(governance.dev_pool, governance.fees_share.dev_pool);(governance.staking, governance.fees_share.staking)] in
    
    List.fold 
    (fun ( acc, k : share_per_address list *  key_hash) -> 
        (key_or_registered_address(k, signers), governance.fees_share.signers / signers_count ) :: acc
    ) 
    p
    other_shares
    

let distribute_tokens (p, s : distribute_param * storage) : fees_storage = 
    let fees_storage = s.fees in
    let governance = s.governance in
    let shares = shares(p.signers, fees_storage.signers, governance) in 
    let new_ledger = tokens_for_share(shares, p.tokens, fees_storage.tokens) in
    {fees_storage with tokens = new_ledger}


let distribute_xtz (p, s : key_hash list * storage) : fees_storage =
    let fees_storage = s.fees in
    let total = xtz_balance(fees_storage.xtz, Tezos.self_address) in
    if total = 0tez 
    then fees_storage
    else
        let governance = s.governance in
        let shares = shares(p, fees_storage.signers, governance) in 

        let apply : (tez * xtz_ledger) * share_per_address -> (tez * xtz_ledger) =
            (fun (acc, share : (tez * xtz_ledger) * share_per_address) -> 
                let (distributed, distribution) = acc in
                let (receiver_address, percent) = share in
                let tez_fees = tez_share(total, percent) in
                let new_ledger = inc_xtz_balance(distribution, receiver_address, tez_fees) in
                (distributed+tez_fees, new_ledger)
                
            ) in
        let (distributed, new_distribution) = List.fold apply shares (0tez, fees_storage.xtz) in    
        let remaining = total - distributed in
        let new_distribution = Big_map.update (Tezos.self_address) remaining new_distribution in
        {fees_storage with xtz = new_distribution}


let oracle_main  (p, s : oracle_entrypoint * storage) : return = 
    match p with
    | Distribute_xtz p ->  ([]: operation list),{s with fees = distribute_xtz(p, s)}
    | Distribute_tokens p -> ([]: operation list), {s with fees = distribute_tokens(p, s)}