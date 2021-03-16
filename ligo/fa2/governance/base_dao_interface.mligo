#if !BASE_DAO_INTERFACE
#define BASE_DAO_INTERFACE

#include "../common/fa2_interface.mligo"


type lock_unlock = 
[@layout:comb]
{
    from_: address;
    proposal_id: token_id;
    amount:nat;
}

type lock_unlock_param = lock_unlock list

type get_total_supply_param = nat contract

type base_dao_entry_points = 
| Lock of lock_unlock_param
| Unlock of lock_unlock_param
| Migrate_dao of address
| Confirm_dao_migration
| Get_total_supply of get_total_supply_param

#endif