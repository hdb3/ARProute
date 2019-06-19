stack build
stack install
mkdir -p arproute
ln arproute.service install.sh $HOME/.local/bin/arprouted arproute
tar czf arproute.tgz arproute
rm -rf arproute
