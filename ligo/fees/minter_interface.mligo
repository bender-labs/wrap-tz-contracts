#include "types.mligo"

type minter_entry_points = 
| Add_token of address
| Set_minter_contract of address
