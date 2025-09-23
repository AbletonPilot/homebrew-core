class H2 < Formula
  desc "Java SQL database"
  homepage "https://www.h2database.com/"
  url "https://github.com/h2database/h2database/releases/download/version-2.4.240/h2-2025-09-22.zip"
  version "2.4.240"
  sha256 "154d7aac3c33cae3dc361ad0c5296040be08ed0508acde6560c03842088d147e"
  license "MPL-2.0"

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, all: "5fd92e04e213f01b78acb580651cf0ef22ccc29ea925e903eed2ddf4f907254b"
  end

  depends_on "openjdk"

  def install
    # Remove windows files
    rm(Dir["bin/*.bat"])

    # Fix the permissions on the script
    # upstream issue, https://github.com/h2database/h2database/issues/3254
    chmod 0755, "bin/h2.sh"

    libexec.install Dir["*"]
    (bin/"h2").write_env_script libexec/"bin/h2.sh", Language::Java.overridable_java_home_env
  end

  service do
    run [opt_bin/"h2", "-tcp", "-web", "-pg"]
    keep_alive false
    working_dir HOMEBREW_PREFIX
  end

  test do
    assert_match "Usage: java org.h2.tools.GUIConsole", shell_output("#{bin}/h2 -help 2>&1")
  end
end
