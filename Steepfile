# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  signature "sig"
  check "app"

  library "json"
  library "digest"
  library "openssl"
  library "cgi"
  library "base64"

  # MethodDefinitionMissing fires for every method declared in sig/stubs/ that AR (or
  # another framework) generates at runtime. These are all genuine Steep limitations —
  # the methods exist but are not written in Ruby source. Suppress to keep LSP clean.
  configure_code_diagnostics(D::Ruby.strict.merge(D::Ruby::MethodDefinitionMissing => nil))
end
