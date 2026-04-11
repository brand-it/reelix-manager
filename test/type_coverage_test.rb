# frozen_string_literal: true

require "test_helper"

# Enforces that every Ruby source file checked by Steep has at least one inline
# type annotation (#:) — unless it is a trivially empty file (no def statements).
#
# This prevents type coverage from silently eroding as new files are added.
class TypeCoverageTest < ActiveSupport::TestCase
  CHECKED_DIRS = %w[
    app/models
    app/clients
    app/tool_box
    app/jobs
    app/services
    app/components
    app/graphql
    app/controllers
    app/helpers
    app/mailers
  ].freeze

  test "all checked source files have inline type annotations or no methods" do
    missing = []

    CHECKED_DIRS.each do |dir|
      Dir.glob(Rails.root.join(dir, "**", "*.rb")).sort.each do |path|
        source = File.read(path)
        has_def    = source.match?(/^\s*def /)
        has_annotation = source.include?("#:")
        missing << path.sub("#{Rails.root}/", "") if has_def && !has_annotation
      end
    end

    assert missing.empty?,
      "The following files have method definitions but no #: type annotations:\n\n" \
      "#{missing.map { |f| "  #{f}" }.join("\n")}\n\n" \
      "Add inline RBS annotations. Example:\n" \
      "  #: (String name) -> void\n" \
      "  def my_method(name)\n"
  end
end
