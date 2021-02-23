type withdraw_tokens_param = 
[@layout:comb]
{
    fa2: address;
    tokens: nat list;
}

type withdraw_token_param = 
[@layout:comb]
{
    fa2: address;
    token_id: nat;
    amount: nat;
}

type withdrawal_entrypoint = 
| Withdraw_all_tokens of withdraw_tokens_param
| Withdraw_all_xtz
| Withdraw_token of withdraw_token_param
| Withdraw_xtz of tez
