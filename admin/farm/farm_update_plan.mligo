#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/farm_update_plan.mligo"

type update_plan_parameter = {
    rewardPerBlock: nat;
    totalBlocks: nat;
}

let update_plan  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%updatePlan" contract_address): update_plan_parameter contract option) with 
        | Some v ->
            ([Tezos.transaction {rewardPerBlock = reward_per_block;totalBlocks=total_blocks} 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let farm_update_plan_payload = 
    let l = Operation update_plan in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p