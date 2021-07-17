#include "../common/constants.mligo"
#include "../common/utils.mligo"

let transfer_to_delegator (reserve,destination, token ,amnt: address * address * token * nat ): operation =
    transfer_one(reserve, destination, token, amnt)
    

let claim(s: storage): contract_return = 
    let s = update_pool(s) in
    let delegator = get_delegator(Tezos.sender, s.ledger.delegators) in
    let reward = earned(delegator, s.reward) in
    let (reward_scaled, remainder) = unscale(reward, target_exponent, s.reward.exponent) in
    if reward_scaled = 0n then
        ([]: operation list), s
    else     
        let delegators = Map.update Tezos.sender (Some {delegator with unpaid = remainder ; reward_per_token_paid = s.reward.accumulated_reward_per_token}) s.ledger.delegators in
        let op  = transfer_to_delegator(s.settings.reserve_contract, Tezos.sender, s.settings.reward_token, reward_scaled) in
        [op], {s with ledger = {s.ledger with delegators = delegators }}