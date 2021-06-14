#include "../reserve/reserve_api.mligo"
#include "../common/constants.mligo"
#include "../common/utils.mligo"

let transfer_to_delegator (reserve,destination,amnt: address * address * nat ): operation =
    match (Tezos.get_entrypoint_opt "%transfer_to_delegator" reserve : transfer_params contract option) with
    | Some ep -> 
        Tezos.transaction {to_=destination; amount=amnt} 0tez ep
    | None -> (failwith "not_reserve_contract":operation)

let claim(s: storage): contract_return = 
    let s = update_pool(s) in
    let current_balance = get_balance(Tezos.sender, s.ledger.balances) in
    let delegator = get_delegator(Tezos.sender, s.delegators) in
    let reward = earned(current_balance, delegator, s.reward) in
    let (reward_scaled, remainder) = scale_precise(reward, target_exponent, s.reward.exponent) in
    if reward_scaled = 0n then
        ([]: operation list), s
    else     
        let delegators = Map.update Tezos.sender (Some {delegator with unpaid = remainder ; reward_per_token_paid = s.reward.accumulated_reward_per_token}) s.delegators in
        let op  = transfer_to_delegator(s.settings.reserve_contract, Tezos.sender, reward_scaled) in
        [op], {s with delegators = delegators }