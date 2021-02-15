#include "governance_interface.mligo"
#include "storage.mligo"

let governance_main (p, s: governance_entry_points * governance_storage): operation list * governance_storage = 
    ([]:operation list), s