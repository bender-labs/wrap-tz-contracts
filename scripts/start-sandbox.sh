#!/bin/bash

docker run --name flextesa-sandbox -e block_time=5 --detach -p 8732:20000 tqtezos/flextesa:20201214 delphibox start