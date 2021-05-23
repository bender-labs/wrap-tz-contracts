#include "../../minter/fees_interface.mligo"

let get_minter_contract_ep(addr:address): withdraw_token_param contract =
    match (Tezos.get_entrypoint_opt "%withdraw_token" addr :withdraw_token_param contract option) with
    | Some v -> v
    | None -> (failwith "not_minter_contract": withdraw_token_param contract)

let claim_fees (p,s: claim_fees_param * storage) : contract_return =
    match (Map.find_opt Tezos.sender s.farms : token option) with
    | Some v -> 
        if v <> (p.fa2, p.token_id) then
            (failwith "TOKEN_MISMATCH":contract_return)
        else            
            let ep = get_minter_contract_ep(s.minter_contract) in
            let op = Tezos.transaction p 0tez ep in
            [op], s
    | None -> 
        (failwith "NOT_STAKING_CONTRACT":contract_return)