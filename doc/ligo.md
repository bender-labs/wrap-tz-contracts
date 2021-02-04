# MacOS

If you want to use ligo on macos, you can use the official docker image, like stated in the doc, 
but if you think that docker for mac has become a huge pile of trash, here is how to build you a version. 
Unfortunately, the makefile delivered with ligo works only on nix or debian, so here is the  trick :

Assuming you have a working opam installed, and checked out ligo source code :
```
brew install libev
opan init --bare # if not done yet
opam switch create tezos 4.09.1
opam install -y --deps-only --with-test ./ligo.opam $(find vendors -name \*.opam)
opam install -y $(find vendors -name \*.opam)
dune build -p ligo
ln -sf ${PWD}/_build/install/default/bin/ligo /usr/local/bin/
```