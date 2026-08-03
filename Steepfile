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
  library 'securerandom'

  # Suppress NoMethod errors for framework-generated methods (ActiveRecord scopes, Config settings)
  # that exist at runtime but can't be verified statically by Steep.
  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :information
    hash[D::Ruby::UnannotatedEmptyCollection] = :information
  end

  # MethodDefinitionMissing warnings are Steep limitations with framework-generated methods.
  # These are false positives - the methods exist at runtime but can't be verified statically.
end
