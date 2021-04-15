#include "storage.mligo"


type contract_admin_entrypoints = 
| Set_administrator of address
| Confirm_minter_admin
| Set_oracle of address
| Set_signer of address
| Pause_contract of bool

let fail_if_not_admin (s:contract_admin_storage) =
  if(s.administrator <> Tezos.sender) then
    failwith("NOT_ADMIN")

let fail_if_not_signer (s:contract_admin_storage) =
  if(s.signer <> Tezos.sender) then
    failwith("NOT_SIGNER")

let fail_if_not_oracle (s:contract_admin_storage) =
  if(s.oracle <> Tezos.sender) then
    failwith("NOT_ORACLE")

let set_administrator ((s, new_administrator):(contract_admin_storage * address)) : (operation list * contract_admin_storage) =
  (([]:operation list), {s with pending_admin = Some new_administrator})

let set_signer ((s, new_signer):(contract_admin_storage * address)):(operation list * contract_admin_storage) =
  (([]:operation list), {s with signer=new_signer})

let pause ((s, p): (contract_admin_storage * bool)) : (operation list * contract_admin_storage) =
  (([]:operation list), {s with paused = p})

let confirm_new_minter_admin (s: contract_admin_storage) : (operation list * contract_admin_storage) = 
  match s.pending_admin with
  | Some(pending_admin)->
    if pending_admin = Tezos.sender then
      ([]:operation list), {s with pending_admin = (None: address option) ; administrator = Tezos.sender}
    else
      (failwith "NOT_A_PENDING_ADMIN": (operation list * contract_admin_storage))
  | None -> (failwith "NO_PENDING_ADMIN": (operation list * contract_admin_storage))

let contract_admin_main ((p, s):(contract_admin_entrypoints * contract_admin_storage)):(operation list * contract_admin_storage) = 
  match p with 
  | Set_administrator(n) -> 
    let _ = fail_if_not_admin(s) in
    set_administrator(s, n)
  | Set_oracle(n) -> 
    let _ = fail_if_not_admin(s) in
    ([]:operation list), {s with oracle = n}
  | Set_signer(n) -> 
    let _ = fail_if_not_admin(s) in
    set_signer(s, n)
  | Confirm_minter_admin -> 
    confirm_new_minter_admin(s)
  | Pause_contract(p) -> 
    let _ = fail_if_not_admin(s) in
    pause(s, p)