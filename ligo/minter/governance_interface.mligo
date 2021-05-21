type bps = nat

type fees_share = 
[@layout:comb]
{
  dev_pool: nat;
  signers: nat;
  staking: nat;
}

type governance_entrypoints = 
| Set_erc20_wrapping_fees of bps
| Set_erc20_unwrapping_fees of bps
| Set_erc721_wrapping_fees of tez
| Set_erc721_unwrapping_fees of tez
| Set_fees_share of fees_share
| Set_governance of  address
| Set_dev_pool of address
| Set_staking of address