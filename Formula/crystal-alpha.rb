class CrystalAlpha < Formula
  desc "Crystal compiler with incremental compilation and WASM support (alpha)"
  homepage "https://github.com/crimson-knight/crystal/tree/incremental-compilation"
  url "https://github.com/crimson-knight/crystal/releases/download/v1.20.0-dev-incremental-3/crystal-alpha-1.20.0-dev-incremental.tar.gz"
  version "1.20.0-dev-incremental-3"
  sha256 "67170994411824b81330a2603896c731db204f4ad286286c960a41aca29543c1"

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

    # Create lib/crystal directory so the default CRYSTAL_LIBRARY_PATH
    # ($ORIGIN/../lib/crystal) resolves without linker warnings.
    (lib/"crystal").mkpath

    # Create wrapper script that sets CRYSTAL_PATH and CRYSTAL_LIBRARY_PATH.
    # CRYSTAL_LIBRARY_PATH defaults to our lib/crystal dir, suppressing the
    # "search path not found" linker warning. Users can override it for
    # cross-compilation (e.g. WASM: CRYSTAL_LIBRARY_PATH=/path/to/wasm-libs).
    (bin/"crystal-alpha").write <<~SH
      #!/bin/sh
      export CRYSTAL_PATH="${CRYSTAL_PATH:-./lib:#{pkgshare}/src}"
      export CRYSTAL_LIBRARY_PATH="${CRYSTAL_LIBRARY_PATH:-#{lib}/crystal}"
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

  def caveats
    <<~EOS
      Crystal Alpha includes incremental compilation and WASM support.
      Warm rebuilds are 3-5x faster than stock Crystal.

      Usage:
        crystal-alpha build hello.cr                  # Standard build
        crystal-alpha build hello.cr --incremental    # Incremental (3-5x warm speedup)
        crystal-alpha build hello.cr --no-cache       # Force full rebuild
        crystal-alpha watch hello.cr                  # Watch mode (recompile on change)

      For WASM compilation:
        CRYSTAL_LIBRARY_PATH=/path/to/wasm-libs crystal-alpha build hello.cr \\
          -o hello.wasm --target wasm32-wasi -Dwithout_iconv -Dwithout_openssl

      Note: WASM requires wasi-sdk libraries, wasmtime, and wasm-opt (Binaryen).
    EOS
  end

  test do
    assert_match "Crystal", shell_output("#{bin}/crystal-alpha --version")

    # Test native compilation
    (testpath/"hello.cr").write 'puts "Hello from Crystal Alpha!"'
    system bin/"crystal-alpha", "build", "hello.cr", "-o", "hello"
    assert_equal "Hello from Crystal Alpha!\n", shell_output("#{testpath}/hello")
  end
end
