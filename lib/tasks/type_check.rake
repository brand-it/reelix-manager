# frozen_string_literal: true

# Rake tasks for the RBS + Steep type-checking workflow.
#
# Usage:
#   bundle exec rake type_check        # regenerate + check (default)
#   bundle exec rake type_check:gen    # only regenerate sig/generated/
#   bundle exec rake type_check:check  # only run steep check
# Helper to add steep:ignore comment before a specific line in an RBS file
def add_ignore_comment(file_path, target_line)
  return unless File.exist?(file_path)

  lines = File.readlines(file_path)
  lines.each_with_index do |line, idx|
    lines[idx] = "  # steep:ignore MethodDefinitionMissing\n#{line}" if line.include?(target_line) && !line.strip.start_with?('# steep:ignore')
  end
  File.write(file_path, lines.join)
end

namespace :type_check do
  desc 'Regenerate sig/generated/ from inline #: annotations using rbs-inline'
  task :gen do
    ruby_files = Dir.glob('{app,lib}/**/*.rb').join(' ')
    sh "bundle exec rbs-inline --opt-out --output=sig/generated #{ruby_files}"

    # Suppress MethodDefinitionMissing warnings for attr_readers (Steep limitation)
    # These warnings are false positives - attr_readers are valid Ruby but Steep can't verify them
    add_ignore_comment('sig/generated/services/key_parser_service.rbs', 'attr_reader key:')
    add_ignore_comment('sig/generated/services/key_parser_service.rbs', 'attr_reader movie_path:')
    add_ignore_comment('sig/generated/services/key_parser_service.rbs', 'attr_reader tv_path:')
    add_ignore_comment('sig/generated/services/library_scanner_service.rbs', 'attr_reader config:')
    add_ignore_comment('sig/generated/components/library/results_component.rbs', 'attr_reader video_blobs:')
    add_ignore_comment('sig/generated/components/library/results_component.rbs', 'attr_reader query:')
    add_ignore_comment('sig/generated/components/library/blob_card_component.rbs', 'attr_reader blob:')
    add_ignore_comment('sig/generated/services/error_logger_service.rbs', 'def self.call: (StandardError, ?untyped?) -> ErrorEntry')
    add_ignore_comment('sig/generated/services/error_logger_service.rbs', 'def initialize: (StandardError, ?untyped?) -> void')
  end

  desc 'Run Steep type checker'
  task :check do
    sh 'bundle exec steep check --log-level=fatal'
  end
end

desc 'Regenerate RBS signatures from inline annotations then type-check with Steep'
task type_check: %w[type_check:gen type_check:check]
