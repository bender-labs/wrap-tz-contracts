#include "multisig_interface.mligo"
#include "build/common_vars.mligo"
#include "build/multisig_change_keys.mligo"
    

let multisig_change_keys_payload = 
    let l = Change_keys ({threshold = threshold; keys = keys}) in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p

