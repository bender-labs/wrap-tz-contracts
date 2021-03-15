(*
    Logic to distribute the $wrap supply
*)

type distribution = {
    to_: address;
    amount: nat;
}

type distribution_param = distribution list

type Distribute_entry_points = 
| Distribute of distribution_param