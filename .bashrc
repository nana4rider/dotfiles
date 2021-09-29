pg() {
  eval 'perl -nlE "say if /${1//\//\\\/}/$2"'
}
pgu() {
  eval 'perl -nlE "say unless /${1//\//\\\/}/$2"'
}