{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:

buildNpmPackage rec {
  pname = "promptfoo";
  version = "0.115.3";

  src = fetchFromGitHub {
    owner = "promptfoo";
    repo = "promptfoo";
    rev = "${version}";
    hash = "sha256-JBDz3kb++oR84mcU5Fxk28NCc5OfLThvBpAD7GiMZx4=";
  };

  npmDepsHash = "sha256-1SfaX3XrmSVXpZKuSbM4LdO7F4d0NCpa1QcpasEMoBw=";

  meta = {
    description = "Test your prompts, models, RAGs. Evaluate and compare LLM outputs, catch regressions, and improve prompt quality";
    mainProgram = "promptfoo";
    homepage = "https://www.promptfoo.dev/";
    changelog = "https://github.com/promptfoo/promptfoo/releases/tag/${version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.nathanielbrough ];
  };

  env = {
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = 1;
  };

  postInstall = ''
    rm $out/lib/node_modules/promptfoo/node_modules/app
    rm $out/lib/node_modules/promptfoo/node_modules/promptfoo-docs
  '';
}
