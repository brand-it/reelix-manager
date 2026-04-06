D = Steep::Diagnostic

# ──────────────────────────────────────────────────────────────────────────────
# :core — models, clients, tool_box, jobs
#
# Fully strict. We own all of this code and have complete RBS signatures for it.
# Every NoMethod call, type mismatch, and unknown constant is an error.
# ──────────────────────────────────────────────────────────────────────────────
target :core do
  signature "sig"

  check "app/models"
  check "app/clients"
  check "app/tool_box"
  check "app/jobs"
  check "app/services"

  # Standard library modules used by app code
  library "pathname"
  library "json"
  library "cgi"
  library "base64"
  library "openssl"
  library "uri"
  library "fileutils"
  library "digest"
  library "securerandom"

  configure_code_diagnostics(D::Ruby.strict)
end

# ──────────────────────────────────────────────────────────────────────────────
# :web — controllers + GraphQL layer
#
# Near-strict. We downgrade NoMethod and UnknownConstant to warnings because
# graphql-ruby and parts of ActionController lack published RBS signatures —
# DSL calls like `field`, `argument`, and `protect_from_forgery` cannot be
# resolved at the type level. Every type safety diagnostic we *can* check
# (argument types, return types, assignments) remains a hard error.
#
# As graphql-ruby gains RBS support, tighten these back to D::Ruby.strict.
# ──────────────────────────────────────────────────────────────────────────────
target :web do
  signature "sig"

  check "app/graphql"
  check "app/controllers"
  check "app/helpers"
  check "app/mailers"

  library "json"

  configure_code_diagnostics(D::Ruby.strict)
end
