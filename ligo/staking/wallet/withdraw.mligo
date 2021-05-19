let decrease_balance (current, amnt, ledger: nat * nat * ledger) : ledger = 
    let balances = Map.update Tezos.sender (Some (sub(current, amnt))) ledger.balances in
    {ledger with total_supply = sub(ledger.total_supply, amnt) ; balances = balances}

let withdraw(amnt, s : nat * storage) : (operation list) * storage = 
    let amnt = check_amnt amnt in
    let (current_balance, s) = update_delegator_and_pool(s) in
    let ledger = decrease_balance(current_balance, amnt, s.ledger) in
    let op = transfer_one (Tezos.self_address, Tezos.sender, s.settings.staked_token, amnt) in
    [op], {s with ledger = ledger }