require "test_helper"

# Enforces that every Ruby file under app/ that Steep type-checks has a
# corresponding RBS signature file under sig/.
#
# When this test fails, run:
#   bundle exec rbs prototype rb <file> > sig/<path>.rbs
# to generate a skeleton, then fill in the types.
class TypeCoverageTest < ActiveSupport::TestCase
  # Directories under app/ whose Ruby files must have sig/**/*.rbs counterparts.
  # app/javascript, app/assets, and app/views are excluded (not Ruby).
  CHECKED_DIRS = %w[
    models
    clients
    controllers
    graphql
    helpers
    jobs
    mailers
    services
    tool_box
  ].freeze

  test "every app Ruby file has a corresponding RBS signature" do
    app_root = Rails.root

    app_files = CHECKED_DIRS.flat_map do |dir|
      Dir[app_root.join("app", dir, "**", "*.rb")]
    end

    missing = app_files.filter_map do |rb_file|
      relative = Pathname.new(rb_file).relative_path_from(app_root).to_s
      rbs_file  = app_root.join(relative.sub("app/", "sig/").sub(/\.rb\z/, ".rbs"))
      relative unless rbs_file.exist?
    end

    assert missing.empty?, <<~MSG
      Missing RBS signatures for #{missing.size} file(s):

      #{missing.map { |f| "  #{f}" }.join("\n")}

      To generate a skeleton for each file, run:
        bundle exec rbs prototype rb <file>

      Then add the output to the corresponding sig/ path and fill in the types.
    MSG
  end
end
