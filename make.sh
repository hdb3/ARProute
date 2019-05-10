cabal install --only-dependencies
cabal configure
cabal build
mkdir -p arproute
ln  arproute.service install.sh dist/build/arprouted/arprouted arproute
tar czf arproute.tgz arproute
rm -rf arproute
