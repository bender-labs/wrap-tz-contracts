#include "../../fa2/common/fa2_interface.mligo"
#include "./storage.mligo"

type withdraw_param = (address * transfer_destination list)

let create_transfer (addr, dests:withdraw_param): operation = 
    let transfer = {
        from_ = Tezos.self_address;
        txs = dests
    } in
    let ep : ((transfer list) contract) option = Tezos.get_entrypoint_opt "%transfer" addr in
    match ep with
    | Some v -> Tezos.transaction [transfer] 0tez v
    | None -> (failwith "not_fa2":operation)

let withdraw_main (p, s: withdraw_param list * storage) : contract_return =
    let ops = List.map create_transfer p in
    ops, s