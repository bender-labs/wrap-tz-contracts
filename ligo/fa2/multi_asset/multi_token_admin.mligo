#include "types.mligo"
#include "../fa2_modules/token_admin.mligo"

let create_token (metadata, storage
    : token_metadata * multi_token_storage) : multi_token_storage =
  (* extract token id *)
  let new_token_id = metadata.token_id in
  let existing_meta = Big_map.find_opt new_token_id storage.token_metadata in
  match existing_meta with
  | Some m -> (failwith "FA2_DUP_TOKEN_ID" : multi_token_storage)
  | None ->
    let meta = Big_map.add new_token_id metadata storage.token_metadata in
    let supply = Big_map.add new_token_id 0n storage.token_total_supply in
    { storage with
      token_metadata = meta;
      token_total_supply = supply;
    }


let multi_token_admin_main (p, s: multi_token_admin * multi_asset_storage): return = 
    match p with
    | Token_admin p ->  
        let ops, admin = token_admin (p, s.admin) in
        let new_s = { s with admin = admin; } in
        (ops, new_s)
    | Create_token p ->
        ([]:operation list), {s with assets = create_token(p, s.assets)}