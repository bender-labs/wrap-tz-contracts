let check_admin (s:storage):storage = 
    if(Tezos.sender <> s.admin.address)
    then (failwith "NOT_AN_ADMIN":storage)
    else s