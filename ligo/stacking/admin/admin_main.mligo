#include "../storage.mligo"
#include "../common/errors.mligo"

type admin_entrypoints = 
| Change_admin of address
| Confirm_new_admin

let check_admin (s: storage):storage = 
    if Tezos.sender <> s.admin.address
    then (failwith not_admin:storage)
    else s

let change_admin(pending_admin, admin : address * admin):admin =
    if pending_admin <> Tezos.sender
    then (failwith not_pending_admin:admin)
    else 
        {admin with pending_admin=(None:address option); address=Tezos.sender}

let confirm_new_admin(s:storage):storage =
    match s.admin.pending_admin with 
    | Some v -> {s with admin = change_admin(v, s.admin)}
    | None -> (failwith no_pending_admin:storage)

let admin_main (p, s: admin_entrypoints * storage): contract_return =
    match p with 
    | Change_admin a -> 
        let s = check_admin(s) in
        ([]:operation list), {s with admin = {s.admin with pending_admin = Some a}}
    | Confirm_new_admin -> 
        ([]:operation list), confirm_new_admin(s)