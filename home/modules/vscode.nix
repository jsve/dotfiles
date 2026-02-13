{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    # userSettings managed outside of nix. use `just vscode-push` and `just vscode-pull` to sync.
    # see configs/vscode/settings.json

    profiles.default = {
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;

      # Extensions
      extensions = (
        with pkgs.vscode-marketplace-release; # https://github.com/nix-community/nix-vscode-extensions/issues/160
        [
          # aaron-bond.better-comments
          # amazonwebservices.aws-toolkit-vscode
          # astro-build.astro-vscode
          # bierner.github-markdown-preview
          # bierner.markdown-checkbox
          # bierner.markdown-emoji
          # bierner.markdown-footnotes
          # bierner.markdown-mermaid
          # bierner.markdown-preview-github-styles
          # bierner.markdown-yaml-preamble
          # bradlc.vscode-tailwindcss
          # ckolkman.vscode-postgres
          # dbaeumer.vscode-eslint
          # dotjoshjohnson.xml
          # eamodio.gitlens
          # ecmel.vscode-html-css
          # esbenp.prettier-vscode
          # firsttris.vscode-jest-runner
          # github.copilot
          # github.copilot-chat
          # github.vscode-github-actions
          # github.vscode-pull-request-github
          # jnoortheen.nix-ide
          # meganrogge.template-string-converter
          # ms-playwright.playwright
          # ms-vsliveshare.vsliveshare
          # nrwl.angular-console
          # pflannery.vscode-versionlens
          # pomdtr.excalidraw-editor
          # quicktype.quicktype
          # redhat.vscode-yaml
          # skellock.just
          # stripe.vscode-stripe
          # tonybaloney.vscode-pets
          # typescriptteam.native-preview
          # upstash.context7-mcp
          # wix.vscode-import-cost
          # yoavbls.pretty-ts-errors
        ]
      );
    };
  };
}
