cabal install --only-dependencies
cabal configure
cabal build
cabal install
mkdir -p arproute
ln  arproute.service install.sh dist/build/arprouted/arprouted arproute
tar czf arproute.tgz arproute
rm -rf arproute
