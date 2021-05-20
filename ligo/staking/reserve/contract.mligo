#include "../../fa2/common/fa2_interface.mligo"

type register_contract = 
[@layout:comb]
{
    staking_contract: address;
    token_contract: address;
    token_id: nat;
}

type contract_management_entrypoints = 
| Register_contract of register_contract
| Remove_contract of address


let get_update_operators_ep (addr:address): update_operator list contract =
    match (Tezos.get_entrypoint_opt "%update_operators" addr: update_operator list contract option) with
    | Some v -> v
    | None -> (failwith "NOT_FA2_CONTRACT":update_operator list contract)

let register_contract (p, s : register_contract * storage): contract_return =
    let ep = get_update_operators_ep(p.token_contract) in
    let updates = [Add_operator {owner=Tezos.self_address;operator=p.staking_contract;token_id=p.token_id}] in
    let op = Tezos.transaction updates 0tez ep in
    let farms = Map.update p.staking_contract (Some (p.token_contract, p.token_id)) s.farms in
    [op], {s with farms = farms}

let contract_management_main (p, s: contract_management_entrypoints * storage): contract_return = 
    match p with 
    | Register_contract p -> register_contract(p, s)
    | Remove_contract -> ([]:operation list), s