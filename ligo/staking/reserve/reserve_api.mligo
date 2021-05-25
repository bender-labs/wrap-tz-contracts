type claim_fees_param = nat

type transfer_params = 
[@layout:comb]
{
    to_: address;
    amount: nat;
}

type staking_contract_entrypoints = 
| Claim_fees of claim_fees_param
| Transfer_to_delegator of transfer_params
