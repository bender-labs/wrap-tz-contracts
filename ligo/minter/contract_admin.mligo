#include "interface.mligo"


type contract_admin_entrypoints = 
| Set_administrator of address
| Set_signer of address
| Pause_contract of bool

let fail_if_not_admin (s:contract_admin_storage) =
  if(s.administrator <> Tezos.sender) then
    failwith("NOT_ADMIN")

let fail_if_not_signer (s:contract_admin_storage) =
  if(s.signer <> Tezos.sender) then
    failwith("NOT_SIGNER")

let set_administrator ((s, new_administrator):(contract_admin_storage * address)) : (operation list * contract_admin_storage) =
  (([]:operation list), {s with administrator = new_administrator})

let set_signer ((s, new_signer):(contract_admin_storage * address)):(operation list * contract_admin_storage) =
  (([]:operation list), {s with signer=new_signer})

let pause ((s, p): (contract_admin_storage * bool)) : (operation list * contract_admin_storage) =
  (([]:operation list), {s with paused = p})

let contract_admin_main ((p, s):(contract_admin_entrypoints * contract_admin_storage)):(operation list * contract_admin_storage) = 
  match p with 
  | Set_administrator(n) -> set_administrator(s, n)
  | Set_signer(n) -> set_signer(s, n)
  | Pause_contract(p) -> pause(s, p)