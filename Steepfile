# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  signature "sig/stubs"
  signature "sig/generated"

  check "app/models"
  check "app/clients"
  check "app/tool_box"
  check "app/jobs"
  check "app/services" if Dir.exist?("app/services")
  check "app/components" if Dir.exist?("app/components")
  check "app/graphql"
  check "app/controllers"
  check "app/helpers"
  check "app/mailers"

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
