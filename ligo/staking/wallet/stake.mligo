let increase_balance (current, amnt, ledger: nat * nat * ledger) : ledger = 
    let balances = Map.update Tezos.sender (Some (current + amnt)) ledger.balances in
    {ledger with total_supply = ledger.total_supply + amnt ; balances = balances}

let stake(amnt, s : nat * storage): (operation list) * storage = 
    let amnt = check_amnt(amnt) in
    let (current_balance, s) = update_delegator_and_pool(s) in
    let ledger = increase_balance(current_balance, amnt, s.ledger) in
    let op = transfer_one (Tezos.sender, Tezos.self_address, s.settings.staked_token, amnt) in
    [op], {s with ledger = ledger}