#include "quorum_interface.mligo"
#include "storage.mligo"

let quorum_main (p, s: quorum_entry_points * quorum_storage) : (operation list * quorum_storage) = 
    ([]: operation list), s