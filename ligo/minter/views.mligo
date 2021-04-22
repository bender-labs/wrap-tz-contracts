#include "storage.mligo"


let get_token_balance ((addr, token_address, ledger):(address * token_address * token_ledger)): nat = 
    let key = (addr, token_address) in
    match Map.find_opt key ledger with
    | Some v -> v
    | None -> 0n

let get_tez_balance ((addr, ledger):(address * xtz_ledger)): tez =
    match Map.find_opt addr ledger with
    | Some v -> v
    | None -> 0tez


type get_token_reward_parameter = 
[@layout:comb]
{
    address: address;
    token_contract: address;
    token_id: nat;
}

type get_token_reward_return = nat

let get_token_reward_view ((p, s): (get_token_reward_parameter * storage)): get_token_reward_return = 
    let ledger = s.fees.tokens in
    let token = (p.token_contract, p.token_id) in
    get_token_balance (p.address, token, ledger)

let get_token_reward_main((p, s): (get_token_reward_parameter * storage)): (operation list * storage) =
    ([]:operation list), s


type get_tez_reward_parameter = address

type get_tez_reward_return = tez

let get_tez_reward_view ((p, s): (get_tez_reward_parameter * storage)): get_tez_reward_return = 
    let ledger = s.fees.xtz in
    get_tez_balance (p, ledger)

let get_tez_reward_main((p, s): (get_tez_reward_parameter * storage)): (operation list * storage) =
    ([]:operation list), s
