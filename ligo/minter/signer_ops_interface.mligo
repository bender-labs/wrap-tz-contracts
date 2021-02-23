
type set_signer_payment_address_param =
[@layout:comb]
{
    signer: key_hash;
    payment_address: address;
}

type signer_ops_entrypoint = | Set_payment_address of set_signer_payment_address_param