# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  signature 'sig'
  signature 'sig/rbs_rails'
  signature 'sig/generated'
  check 'app'

  library 'json'
  library 'digest'
  library 'openssl'
  library 'cgi'
  library 'base64'

  # MethodDefinitionMissing warnings are Steep limitations with framework-generated methods.
  # These are false positives - the methods exist at runtime but can't be verified statically.
end
