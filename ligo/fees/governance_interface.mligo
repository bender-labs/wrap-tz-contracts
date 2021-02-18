type fees_ratio = 
{
    dev:nat;
    staking:nat;
    signers:nat;
}

type governance_entry_points = 
| Set_governance of address
| Set_fees_ratio of fees_ratio