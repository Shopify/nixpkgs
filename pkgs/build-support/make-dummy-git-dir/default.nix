{ stdenvNoCC, git }:

{ src, ... }:
stdenvNoCC.mkDerivation {
  name = src.name + "-with-dummy-git-dir";

  inherit src;
  # buildInputs = [ src ];
  nativeBuildInputs = [ git ];

  # support `git ls-files`, but don't actually copy any of the content.
  buildPhase = ''
    rm -rf .git
    ${git}/bin/git init
    rm -rf .git/logs/ .git/hooks/ .git/index .git/FETCH_HEAD .git/ORIG_HEAD .git/refs/remotes/origin/HEAD .git/config
    # create empty entries in the index for each file, but don't copy contents
    ${git}/bin/git add --intent-to-add .
  '';

  # cp -al: recursive hardlink copy
  installPhase = ''
    set -e
    cp -al ${src} $out
    rm -rf $out/.git

    # Bundler wants to mutate gemspecs. Un-hardlink them and make them writable.
    (
      cd ${src} && find . -name '*.gemspec' -print0 | xargs -n1 -0 bash -xec "
        f=\"$out/\$1\"
        d=\$(dirname \"\$f\")
        chmod +w \$d
        rm -f $out/\$1
        cp ${src}/\$1 $out/\$1
        chmod +w $out/\$1
        chmod -w \$d
      " --
    )

    chmod +w $out
    mv .git $out
  '';

  # # symlink everything except .git (if present) from $src, then copy in our .git.
  # installPhase = ''
  #   mkdir -p $out
  #   (
  #     cd ${src}
  #     find . -mindepth 1 -maxdepth 1 -name .git -prune -o -execdir \
  #       ln -sf '${src}/{}' "$out/{}" ';'
  #   )
  #   mv .git $out
  # '';

}
