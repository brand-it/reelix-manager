# frozen_string_literal: true

D = Steep::Diagnostic

target :core do
  signature "sig"

  check "app/models"
  check "app/clients"
  check "app/tool_box"
  check "app/jobs"
  check "app/services" if Dir.exist?("app/services")

  library "json"
  library "digest"
  library "openssl"
  library "cgi"
  library "base64"

  configure_code_diagnostics(D::Ruby.strict)
end

target :web do
  signature "sig"

  check "app/graphql"
  check "app/controllers"
  check "app/helpers"
  check "app/mailers"

  library "json"

  configure_code_diagnostics(D::Ruby.strict)
end
