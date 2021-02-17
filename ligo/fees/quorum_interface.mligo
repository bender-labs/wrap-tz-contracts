type distribute_param = 
[@layout:comb]
{
    signers: key_hash list;
    tokens: (address * nat) list;
}

type set_signer_payment_address_param =
[@layout:comb]
{
    signer: key_hash;
    payment_address: address;
}

type quorum_entry_points = 
| Set_quorum_contract of address
| Set_signer_payment_address of set_signer_payment_address_param
| Distribute of distribute_param