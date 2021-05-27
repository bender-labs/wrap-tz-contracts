#if !FA2_LIB
#define FA2_LIB

#include "../../fa2/common/fa2_interface.mligo"

let transfer_one ((from_, to_, token, amnt):(address * address * token * nat)): operation = 
    let (addr, token_id) = token in
    let transfer = {
        from_ = from_;
        txs = [{to_ = to_ ; amount = amnt ; token_id = token_id}]
    } in
    let ep : ((transfer list) contract) option = Tezos.get_entrypoint_opt "%transfer" addr in
    match ep with
    | Some v -> Tezos.transaction [transfer] 0tez v
    | None -> (failwith "not_fa2":operation)

#endif