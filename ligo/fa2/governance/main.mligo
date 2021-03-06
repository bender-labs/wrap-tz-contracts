#include "./types.mligo"
#include "./fa2.mligo"
#include "../fa2_modules/token_admin.mligo"
#include "./base_dao.mligo"

type param =
  | Assets of fa2_entry_points
  | Admin of token_admin
  | Dao of base_dao_entry_points

let main (p, s : param * storage) : return = 
match p with 
| Assets p -> 
    let u2 = fail_if_paused (s.admin, p) in  
    fa2_main(p, s)
| Admin p ->  
    let ops, admin = token_admin (p, s.admin) in
    let new_s = { s with admin = admin; } in
    (ops, new_s)
| Dao p -> 
    base_dao_main (p, s)