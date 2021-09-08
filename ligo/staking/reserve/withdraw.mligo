#include "../../fa2/common/fa2_interface.mligo"
#include "./minter_contract_lib.mligo"
#include "./storage.mligo"


type withdraw_param = (address * transfer_destination list)

type withdraw_xtz_param = (address * tez)

type withdraw_entrypoint = 
 | Withdraw_fa2_fees of withdraw_param list
 | Withdraw_xtz_fees of withdraw_xtz_param


let create_transfer (addr, dests:withdraw_param): operation = 
    let transfer = {
        from_ = Tezos.self_address;
        txs = dests
    } in
    let ep : ((transfer list) contract) option = Tezos.get_entrypoint_opt "%transfer" addr in
    match ep with
    | Some v -> Tezos.transaction [transfer] 0tez v
    | None -> (failwith "not_fa2":operation)

let withdraw_fa2 (p, s: withdraw_param list * storage) : contract_return =
    let ops = List.map create_transfer p in
    ops, s

let get_payment_contract (addr:address) : unit contract = 
    match (Tezos.get_contract_opt addr : unit contract option) with 
    | Some v -> v
    | None -> (failwith "address_not_payable": unit contract)

let withdraw_xtz (p, s: withdraw_xtz_param * storage) : contract_return =
    let (_to, amnt) = p in
    let ep = get_minter_withdraw_xtz_ep s.minter_contract in
    let payment_address = get_payment_contract _to in

    let ops = [
        Tezos.transaction amnt 0tez ep;
        Tezos.transaction () amnt payment_address
    ] in 
    ops, s

let withdraw_main (p, s: withdraw_entrypoint * storage) : contract_return =
    match p with
    | Withdraw_fa2_fees p -> withdraw_fa2(p, s)
    | Withdraw_xtz_fees p -> withdraw_xtz(p, s)