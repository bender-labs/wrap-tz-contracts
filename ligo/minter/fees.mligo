#include "../fa2/common/fa2_interface.mligo"
#include "fees_interface.mligo"
#include "fees_lib.mligo"
#include "storage.mligo"

let balance_sheet_or_default (k,token, ledger : address * token_address * token_ledger): nat =
    match Big_map.find_opt (k,token) ledger with
    | Some v -> v
    | None -> 0n

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
            | None -> 0n
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
        let remaining = if (total - distributed) >= 0tez then (total - distributed) else 0tez in  
        let new_distribution = Big_map.update (Tezos.self_address) (Some remaining) new_distribution in
        {fees_storage with xtz = new_distribution}

let transfer_xtz (addr, value : address * tez) : operation =
    match (Tezos.get_contract_opt addr : unit contract option) with
    | Some c -> Tezos.transaction unit value c
    | None -> (failwith "NOT_PAYABLE":operation)


let withdraw_xtz (a,s: tez option * xtz_ledger) : (operation list) * xtz_ledger=
    let available = xtz_balance(s, Tezos.sender) in
    let value = 
        match a with
        | Some v -> 
            if v > available then (failwith "NOT_ENOUGH_XTZ": tez)
            else v
        | None -> available
        in
    if available = 0tez then ([]:operation list), s
    else
        let op = transfer_xtz(Tezos.sender, value) in 
        let new_d = 
            if available - value = 0tez 
            then Big_map.remove Tezos.sender s
            else Big_map.update Tezos.sender (Some (available - value)) s
            in
        [op], new_d
    
type tx_result = (transfer_destination list) * token_ledger


let generate_tx_destinations (p, ledger : withdraw_tokens_param * token_ledger) : tx_result =
    List.fold
      (fun (acc, token_id : tx_result * token_id) ->
        let dsts, s = acc in
        let key = p.fa2, token_id in
        let available = token_balance(ledger, Tezos.sender, key) in
        if available = 0n then acc
        else
          let new_dst : transfer_destination = {
            to_ = Tezos.sender;
            token_id = token_id;
            amount = available;
          } in
          let new_ledger = Big_map.remove (Tezos.sender, key) ledger in
          new_dst :: dsts, new_ledger
      ) p.tokens (([] : transfer_destination list), ledger)

let transfer_operation (from, fa2, dests: address * address * transfer_destination list): operation = 
    let tx : transfer = {
      from_ = from;
      txs = dests;
    } in
    let fa2_entry : ((transfer list) contract) option = 
    Tezos.get_entrypoint_opt "%transfer"  fa2 in
    match fa2_entry with
    | None -> (failwith "CANNOT CALLBACK FA2" : operation)
    | Some c -> Tezos.transaction [tx] 0mutez c

let generate_tokens_transfer (p, ledger : withdraw_tokens_param * token_ledger)
    : (operation list) * token_ledger =
  let tx_dests, new_s = generate_tx_destinations (p, ledger) in
  if List.size tx_dests = 0n
  then ([] : operation list), new_s
  else
    let callback_op = transfer_operation(Tezos.self_address, p.fa2, tx_dests) in
    [callback_op], new_s

let generate_token_transfer(p, ledger: withdraw_token_param * token_ledger): (operation list) * token_ledger = 
    let key = (p.fa2, p.token_id) in
    let available = token_balance(ledger, Tezos.sender, key) in
    let new_b = match Michelson.is_nat(available - p.amount) with
    | None -> (failwith("NOT_ENOUGH_BALANCE"):nat)
    | Some(n) -> n 
    in

    let destination : transfer_destination = {
        to_ = Tezos.sender;
        token_id = p.token_id;
        amount = p.amount;
    } in
    let callback_op = transfer_operation(Tezos.self_address, p.fa2, [destination]) in
    let new_ledger = Big_map.update (Tezos.sender, key) (Some new_b) ledger in
    [callback_op], new_ledger

let withdraw (p, s: withdrawal_entrypoint * storage): return =
    match p with
    | Withdraw_all_tokens p ->
        let ops, new_b = generate_tokens_transfer(p, s.fees.tokens) in
        ops, {s with fees.tokens = new_b}
    | Withdraw_all_xtz -> 
        let ops, new_b = withdraw_xtz((None: tez option), s.fees.xtz) in
        ops, { s with fees.xtz = new_b }
    | Withdraw_token p -> 
        let ops, new_b = generate_token_transfer(p, s.fees.tokens) in
        ops, {s with fees.tokens = new_b}
    | Withdraw_xtz a -> 
        let ops, new_b = withdraw_xtz((Some a), s.fees.xtz) in
        ops, { s with fees.xtz = new_b }

let quorum_ops (p, s: quorum_fees_entrypoint * storage) : return = 
    match p with
    | Set_signer_payment_address p -> 
        let new_quorum = Map.update p.signer (Some p.payment_address) s.fees.signers in
        ([]: operation list), {s with fees.signers = new_quorum}
    | Distribute_xtz p ->  ([]: operation list),{s with fees = distribute_xtz(p, s)}
    | Distribute_tokens p -> ([]: operation list), {s with fees = distribute_tokens(p, s)}

let fees_main  (p, s : fees_entrypoint * storage) : return = 
    match p with 
    | Withdraw p -> withdraw(p, s)
    | Quorum_ops p ->  
        let ignore = fail_if_not_signer(s.admin) in
        quorum_ops(p, s)

