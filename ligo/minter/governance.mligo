#include "interface.mligo"

type bps = nat

type governance_entrypoints = 
| Set_wrapping_fees of bps
| Set_unwrapping_fees of bps
| Set_fees_contract of address
| Set_governance of  address
  

let fail_if_not_governance (s:governance_storage) =
  if(s.contract <> Tezos.sender) then
    failwith("NOT_GOVERNANCE")
  

let set_wrapping_fees ((value, s) : (nat * governance_storage)): governance_storage = 
  {s with  wrapping_fees = value}

let set_unwrapping_fees ((value,s) : (nat * governance_storage)): governance_storage =
  {s with  unwrapping_fees = value}

let set_governance ((new_governance, s):(address * governance_storage)): governance_storage =
  {s with  contract = new_governance}

let set_fees_contract  ((new_fees_contract, s):(address * governance_storage)): governance_storage = 
  {s with  fees_contract = new_fees_contract }

let governance_main ((p, s):(governance_entrypoints * governance_storage)):(operation list * governance_storage) =
  match p with 
  | Set_wrapping_fees(n) -> (([]:operation list), set_wrapping_fees(n, s))
  | Set_unwrapping_fees(n) -> (([]:operation list), set_unwrapping_fees(n, s))
  | Set_fees_contract(a) -> (([]:operation list), set_fees_contract(a, s))
  | Set_governance(a) -> (([]:operation list), set_governance(a, s))
