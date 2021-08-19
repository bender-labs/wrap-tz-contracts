#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/farm_set_admin.mligo"

type set_admin_parameter = {
    address: address;
}

let set_admin  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%setAdmin" contract_address): set_admin_parameter contract option) with 
        | Some v ->
            ([Tezos.transaction {address = new_admin_address} 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let farm_set_admin_payload = 
    let l = Operation set_admin in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p