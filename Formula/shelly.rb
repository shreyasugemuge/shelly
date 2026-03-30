class Shelly < Formula
  desc "Modular zsh configuration with dev workspace and system monitoring"
  homepage "https://github.com/shreyasugemuge/shelly"
  url "https://github.com/shreyasugemuge/shelly/archive/refs/tags/v4.8.1.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  def install
    bin.install "bin/shelly"
    pkgshare.install Dir["*"] - ["bin"]
  end

  def caveats
    <<~EOS
      Shelly has been installed to #{HOMEBREW_PREFIX}/share/shelly.

      To activate, run:
        shelly install

      This copies zsh config files to ~/.config/zsh/ and ~/.zshrc.
      Your existing configs will be backed up automatically.

      After installing, reload your shell:
        exec zsh

      To update config files after a brew upgrade:
        shelly update
    EOS
  end

  test do
    assert_match "shelly v", shell_output("#{bin}/shelly version")
  end
end
