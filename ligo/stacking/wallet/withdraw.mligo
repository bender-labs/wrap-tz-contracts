let get_stake (delegator, stake_index: delegator * nat): stake = 
    match (Map.find_opt stake_index delegator.stakes) with
        | Some v -> v
        | None -> (failwith "WRONG_STAKE_INDEX":stake)
            

let decrease_balance_at_stake (delegator, stake_index, amnt, ledger: delegator * nat * nat * ledger) : nat * ledger =
    let stake = get_stake(delegator, stake_index) in

    let new_balance = sub(stake.amount, amnt) in
    
    let stakes = 
        if new_balance = 0n
        then Map.remove stake_index delegator.stakes
        else Map.update stake_index (Some {stake with amount = sub(stake.amount, amnt)}) delegator.stakes
        in  

    let delegator = {delegator with stakes = stakes ; balance = sub(delegator.balance, amnt)} in
    stake.level, {ledger with 
        total_supply = sub(ledger.total_supply, amnt); 
        delegators = Map.update Tezos.sender (Some delegator) ledger.delegators }
   

let withdraw(stake_index, amnt, s : nat * nat * storage) : (operation list) * storage = 
    let amnt = check_amount(amnt, bad_amount) in
    let (delegator, s) = update_delegator_and_pool(s) in
    let (level, ledger) = decrease_balance_at_stake(delegator, stake_index, amnt, s.ledger) in
    let (withdraw_amount, burn) = withdrawal_fees(level, amnt, s.fees) in
    let op = 
        if burn = 0n 
        then transfer_one (Tezos.self_address, Tezos.sender,s.settings.staked_token, withdraw_amount)
        else transfer_multiple (Tezos.self_address, s.settings.staked_token,[ (Tezos.sender, withdraw_amount) ; (s.fees.burn_address, burn)])
        in
        
    [op], {s with ledger = ledger }