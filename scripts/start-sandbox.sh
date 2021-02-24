#!/bin/bash

docker run --rm --name flextesa-sandbox -e block_time=5 --detach -p 8732:20000 tqtezos/flextesa:20210216 edobox start