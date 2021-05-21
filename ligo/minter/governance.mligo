#include "governance_interface.mligo"
#include "storage.mligo"


let fail_if_not_governance (s:governance_storage) =
  if(s.contract <> Tezos.sender) then
    failwith("NOT_GOVERNANCE")
  

let set_erc20_wrapping_fees ((value, s) : (nat * governance_storage)): governance_storage = 
  {s with erc20_wrapping_fees = value}

let set_erc20_unwrapping_fees ((value,s) : (nat * governance_storage)): governance_storage =
  {s with erc20_unwrapping_fees = value}

let set_erc721_wrapping_fees ((value, s) : (tez * governance_storage)): governance_storage = 
  {s with erc721_wrapping_fees = value}

let set_erc721_unwrapping_fees ((value,s) : (tez * governance_storage)): governance_storage =
  {s with erc721_unwrapping_fees = value}

let set_governance ((new_governance, s):(address * governance_storage)): governance_storage =
  {s with contract = new_governance}

let governance_main ((p, s):(governance_entrypoints * governance_storage)):(operation list * governance_storage) =
  match p with 
  | Set_erc20_wrapping_fees(n) -> (([]:operation list), set_erc20_wrapping_fees(n, s))
  | Set_erc20_unwrapping_fees(n) -> (([]:operation list), set_erc20_unwrapping_fees(n, s))
  | Set_erc721_wrapping_fees(n) -> (([]:operation list), set_erc721_wrapping_fees(n, s))
  | Set_erc721_unwrapping_fees(n) -> (([]:operation list), set_erc721_unwrapping_fees(n, s))
  | Set_governance(a) -> (([]:operation list), set_governance(a, s))
  | Set_dev_pool p -> ([]:operation list), {s with dev_pool = p}
  | Set_staking p -> ([]:operation list), {s with staking = p}
  | Set_fees_share p -> 
      if (p.dev_pool + p.staking + p.signers) <> 100n then
          (failwith "BAD_FEES_RATIO": (operation list) * governance_storage)
      else 
          ([]:operation list), {s with fees_share = p}
