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
  check "app/graphql"
  check "app/controllers"
  check "app/helpers"
  check "app/mailers"

  library "json"
  library "digest"
  library "openssl"
  library "cgi"
  library "base64"

  configure_code_diagnostics(D::Ruby.strict)
end
