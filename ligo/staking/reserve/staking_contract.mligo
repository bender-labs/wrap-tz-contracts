#include "../../minter/fees_interface.mligo"
#include "../fa2/fa2_lib.mligo"

let get_minter_contract_ep(addr:address): withdraw_token_param contract =
    match (Tezos.get_entrypoint_opt "%withdraw_token" addr :withdraw_token_param contract option) with
    | Some v -> v
    | None -> (failwith "not_minter_contract": withdraw_token_param contract)

let claim_fees (p, token, s: claim_fees_param * token * storage) : contract_return =
    let ep = get_minter_contract_ep(s.minter_contract) in
    let (token_contract, token_id) = token in
    let op = Tezos.transaction {fa2=token_contract;token_id=token_id;amount=p} 0tez ep in
    [op], s
    
let transfer_reward (p,token,s:transfer_params * token * storage): contract_return =
    let op = transfer_one(Tezos.self_address, p.to_, token, p.amount) in
    [op],s

let staking_main (p, s: staking_contract_entrypoints * storage): contract_return =
match (Map.find_opt Tezos.sender s.farms : token option) with
| Some token -> (
    match p with
    | Claim_fees p -> claim_fees(p, token, s)
    | Transfer_to_delegator p -> transfer_reward(p, token, s))
| None -> (failwith "NOT_STAKING_CONTRACT" : contract_return)