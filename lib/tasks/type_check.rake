# Rake tasks for the RBS + Steep type-checking workflow.
#
# Usage:
#   bundle exec rake type_check        # regenerate + check (default)
#   bundle exec rake type_check:gen    # only regenerate sig/generated/
#   bundle exec rake type_check:check  # only run steep check
namespace :type_check do
  desc "Regenerate sig/generated/ from inline #: annotations using rbs-inline"
  task :gen do
    ruby_files = Dir.glob("{app,lib}/**/*.rb").sort.join(" ")
    sh "bundle exec rbs-inline --opt-out --output=sig/generated #{ruby_files}"
  end

  desc "Run Steep type checker"
  task :check do
    sh "bundle exec steep check --log-level=fatal"
  end
end

desc "Regenerate RBS signatures from inline annotations then type-check with Steep"
task type_check: %w[type_check:gen type_check:check]
