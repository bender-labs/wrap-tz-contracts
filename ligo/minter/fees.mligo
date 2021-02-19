type withdraw_tokens_param = {
    fa2: address;
    tokens: token_id list;
}

type withdrawal_entrypoint = 
| Withdraw_tokens of withdraw_tokens_param
| Withdraw_xtz

type quorum_fees_entrypoint =
| Set_signer_payment_address of set_signer_payment_address_param
| Distribute of distribute_param

type fees_entrypoint = 
| Withdraw of withdrawal_entrypoint
| Manage of quorum_fees_entrypoint