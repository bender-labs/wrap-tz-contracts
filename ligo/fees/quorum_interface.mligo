type distribute_param = 
[@layout:comb]
{
    signers: key_hash list;
    tokens: (address * nat list) list;
}

type quorum_entry_points = 
| Set_quorum_contract of address
| Set_signer_payment_address of key_hash
| Distribute of distribute_param