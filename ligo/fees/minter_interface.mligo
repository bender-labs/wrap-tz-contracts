#include "types.mligo"

type minter_entry_points = 
| Add_token of token_list
| Set_minter_contract of address
