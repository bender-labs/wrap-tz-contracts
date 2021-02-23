#include "../fa2/common/fa2_interface.mligo"
#include "fees_interface.mligo"
#include "fees_lib.mligo"
#include "storage.mligo"


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
    let fa2_entry : (transfer list) contract = token_transfer_entrypoint(fa2) in
    Tezos.transaction [tx] 0mutez fa2_entry

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
    // todo: virer la clef si 0
    let new_ledger = 
        if new_b = 0n 
        then Big_map.remove (Tezos.sender, key)  ledger 
        else Big_map.update (Tezos.sender, key) (Some new_b) ledger
        in
    [callback_op], new_ledger

let fees_main (p, s: withdrawal_entrypoint * storage): return =
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



