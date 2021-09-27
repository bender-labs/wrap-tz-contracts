let increase_balance (delegator, amnt, ledger: delegator * nat * ledger) : ledger =
    let new_stakes = Map.add delegator.counter {amount=amnt;level=Tezos.level } delegator.stakes in
    let delegator = {delegator with counter = delegator.counter + 1n ; stakes = new_stakes ; balance = delegator.balance + amnt } in
    {ledger with delegators = Map.update Tezos.sender (Some delegator) ledger.delegators; total_supply = ledger.total_supply + amnt}

let stake(amnt, s : nat * storage): (operation list) * storage = 
    let amnt = check_amount(amnt, bad_amount) in
    let (delegator, s) = update_delegator_and_pool(s) in
    let ledger = increase_balance(delegator, amnt, s.ledger) in
    let op = transfer_one (Tezos.sender, Tezos.self_address, s.settings.staked_token, amnt) in
    [op], {s with ledger = ledger}