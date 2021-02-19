#include "storage.mligo"

type bps = nat


type governance_entrypoints = 
| Set_erc20_wrapping_fees of bps
| Set_erc20_unwrapping_fees of bps
| Set_erc721_wrapping_fees of tez
| Set_erc721_unwrapping_fees of tez
| Set_fees_share of fees_share
| Set_governance of  address
  

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
  | Set_fees_share p -> (failwith "not implemented": (operation list) * governance_storage)
