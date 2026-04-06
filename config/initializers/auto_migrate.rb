# frozen_string_literal: true

# Automatically creates the schema (fresh install) or runs pending migrations
# (existing install) at server boot. This removes the need for any manual
# `rails db:migrate` or `rails db:prepare` step in deployment.
#
# Runs only when:
#   - The Rails server process is booting (Rails::Server is defined), OR
#   - AUTO_MIGRATE=1 is set explicitly (useful for custom entrypoints / Docker).
#
# Always skipped when:
#   - A db:* rake task is running (db:migrate, db:schema:load, etc.) to avoid
#     re-entrant or conflicting schema changes.
#   - Any other non-server context: assets:precompile, console, runners, etc.
#
# A file lock prevents concurrent attempts when multiple processes boot at the
# same time (e.g. Puma cluster mode or parallel container starts).
Rails.application.config.after_initialize do
  server_boot  = Rails.const_defined?(:Server)
  auto_migrate = ENV["AUTO_MIGRATE"] == "1"
  db_task      = defined?(Rake) &&
                 Rake.respond_to?(:application) &&
                 Rake.application.respond_to?(:top_level_tasks) &&
                 Rake.application.top_level_tasks.any? { |t| t.match?(/\Adb:/) }

  next unless (server_boot || auto_migrate) && !db_task

  lock_path = Rails.root.join("tmp/migrate.lock")

  File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |lock|
    lock.flock(File::LOCK_EX)

    conn = ActiveRecord::Base.connection

    if conn.table_exists?("schema_migrations")
      # Existing database — run any pending migrations.
      context = ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)

      if context.needs_migration?
        Rails.logger.info "[boot] Pending migrations found — running now."
        context.migrate
        Rails.logger.info "[boot] Migrations complete."
      end
    else
      # Fresh database — load the full schema instead of replaying every migration.
      Rails.logger.info "[boot] Fresh database detected — loading schema."
      load(Rails.root.join("db/schema.rb"))
      Rails.logger.info "[boot] Schema loaded."
    end
  ensure
    lock.flock(File::LOCK_UN)
  end
rescue => e
  Rails.logger.error "[boot] Database setup failed: #{e.message}"
  raise # Refuse to start with a broken schema.
end
