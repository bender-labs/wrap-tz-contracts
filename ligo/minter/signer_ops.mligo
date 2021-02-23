#include "signer_ops_interface.mligo"
#include "storage.mligo"

let signer_ops_main (p, s: signer_ops_entrypoint * storage) : return = 
    match p with
    | Set_payment_address p -> 
        let new_quorum = Map.update p.signer (Some p.payment_address) s.fees.signers in
        ([]: operation list), {s with fees.signers = new_quorum}
