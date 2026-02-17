class CrystalAlpha < Formula
  desc "Crystal compiler with incremental compilation (alpha)"
  homepage "https://crystal-lang.org"
  url "https://github.com/crimson-knight/crystal/releases/download/v1.20.0-dev-incremental-2/crystal-alpha-1.20.0-dev-incremental.tar.gz"
  version "1.20.0-dev-incremental-2"
  sha256 "39455284c519a08a384f2c5236d690f0b95994f1f3b43fa16a1282fe23d9b6c8"

  depends_on "bdw-gc"
  depends_on "gmp"
  depends_on "libevent"
  depends_on "libyaml"
  depends_on "llvm"
  depends_on "openssl@3"
  depends_on "pcre2"
  depends_on "pkgconf"

  uses_from_macos "libffi"

  def install
    # Install the pre-built binary
    bin.install ".build/crystal" => "crystal-alpha-bin"

    # Create wrapper script
    (bin/"crystal-alpha").write <<~SH
      #!/bin/sh
      export CRYSTAL_PATH="${CRYSTAL_PATH:-./lib:#{pkgshare}/src}"
      if [ -n "${CRYSTAL_LIBRARY_PATH}" ]; then
        export CRYSTAL_LIBRARY_PATH="${CRYSTAL_LIBRARY_PATH}"
      fi
      exec "#{bin}/crystal-alpha-bin" "$@"
    SH
    chmod 0755, bin/"crystal-alpha"

    # Install stdlib source
    pkgshare.install "src"

    # Install shell completions (renamed for crystal-alpha command)
    # Bash completion
    bash_content = (buildpath/"etc/completion.bash").read
      .gsub("complete -o default -F _crystal crystal",
            "complete -o default -F _crystal crystal-alpha")
    (bash_completion/"crystal-alpha").write bash_content

    # Zsh completion
    zsh_content = (buildpath/"etc/completion.zsh").read
      .sub("#compdef crystal", "#compdef crystal-alpha")
      .sub("compdef _crystal crystal", "compdef _crystal crystal-alpha")
    (zsh_completion/"_crystal-alpha").write zsh_content

    # Fish completion
    fish_content = (buildpath/"etc/completion.fish").read
      .gsub("complete -c crystal", "complete -c crystal-alpha")
    (fish_completion/"crystal-alpha.fish").write fish_content
  end

  test do
    assert_match "Crystal", shell_output("#{bin}/crystal-alpha --version")
  end
end
