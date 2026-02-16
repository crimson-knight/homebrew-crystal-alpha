class CrystalAlpha < Formula
  desc "Crystal compiler with incremental compilation (alpha)"
  homepage "https://crystal-lang.org"
  url "file:///Users/crimsonknight/open_source_coding_projects/crystal/.build/crystal"
  version "1.20.0-dev-incremental"
  sha256 :no_check

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
    source_root = Pathname.new("/Users/crimsonknight/open_source_coding_projects/crystal")

    # Install the pre-built binary
    bin.install source_root/".build/crystal" => "crystal-alpha-bin"

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
    pkgshare.install source_root/"src"

    # Install shell completions (renamed for crystal-alpha command)
    # Bash completion
    bash_comp = source_root/"etc/completion.bash"
    bash_content = bash_comp.read.gsub("complete -o default -F _crystal crystal",
                                       "complete -o default -F _crystal crystal-alpha")
    (bash_completion/"crystal-alpha").write bash_content

    # Zsh completion
    zsh_comp = source_root/"etc/completion.zsh"
    zsh_content = zsh_comp.read
      .sub("#compdef crystal", "#compdef crystal-alpha")
      .sub("compdef _crystal crystal", "compdef _crystal crystal-alpha")
    (zsh_completion/"_crystal-alpha").write zsh_content

    # Fish completion
    fish_comp = source_root/"etc/completion.fish"
    fish_content = fish_comp.read.gsub("complete -c crystal", "complete -c crystal-alpha")
    (fish_completion/"crystal-alpha.fish").write fish_content
  end

  test do
    assert_match "Crystal", shell_output("#{bin}/crystal-alpha --version")
  end
end
