#include "minter_interface.mligo"
#include "storage.mligo"

let minter_main (p, s: minter_entry_points*minter_storage): (operation list) * minter_storage =
    ([]:operation list), s
