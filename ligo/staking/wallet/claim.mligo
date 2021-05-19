let claim(s: storage): contract_return = 
    let s = update_pool(s) in
    let current_balance = get_balance(Tezos.sender, s.ledger.balances) in
    let delegator = get_delegator(Tezos.sender, s.delegators) in
    let reward = earned(current_balance, delegator, s.reward) in
    let delegators = Map.update Tezos.sender (Some {delegator with unpaid = 0n ; reward_per_token_paid = s.reward.accumulated_reward_per_token}) s.delegators in
    let op  = transfer_one(s.settings.reserve_contract, Tezos.sender, s.settings.reward_token, reward) in
    [op], {s with delegators = delegators }