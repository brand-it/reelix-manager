# frozen_string_literal: true

# Automatically creates the schema (fresh install) or runs pending migrations
# (existing install) at server boot for ALL configured databases.
#
# In single-database environments (e.g. development), SolidQueue and SolidCache
# share the primary database. Their schemas (db/queue_schema.rb,
# db/cache_schema.rb) are loaded into the primary database when their sentinel
# tables are absent.
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

    configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)

    configs.each do |db_config|
      schema_path = ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(db_config)

      original_config = ActiveRecord::Base.connection_db_config
      ActiveRecord::Base.establish_connection(db_config)

      begin
        conn = ActiveRecord::Base.connection

        if conn.table_exists?("schema_migrations")
          migrations_paths = Array(db_config.migrations_paths).presence ||
                               ActiveRecord::Migrator.migrations_paths
          ctx = ActiveRecord::MigrationContext.new(migrations_paths)

          if ctx.needs_migration?
            Rails.logger.info "[boot] Pending migrations for '#{db_config.name}' — running now."
            ctx.migrate
            Rails.logger.info "[boot] Migrations complete for '#{db_config.name}'."
          end
        elsif File.exist?(schema_path)
          Rails.logger.info "[boot] Fresh '#{db_config.name}' database — loading schema."
          load(schema_path)
          Rails.logger.info "[boot] Schema loaded for '#{db_config.name}'."
        end
      ensure
        ActiveRecord::Base.establish_connection(original_config)
      end
    end

    # In single-database environments (e.g. development), SolidQueue and
    # SolidCache share the primary database but have separate schema files.
    # Load them into the primary database when their tables are absent.
    if configs.size == 1
      conn = ActiveRecord::Base.connection

      {
        "solid_queue_processes" => "db/queue_schema.rb",
        "solid_cache_entries"   => "db/cache_schema.rb"
      }.each do |sentinel_table, schema_file|
        path = Rails.root.join(schema_file)
        next unless File.exist?(path)
        next if conn.table_exists?(sentinel_table)

        Rails.logger.info "[boot] Loading #{schema_file} into primary database."
        load(path)
        Rails.logger.info "[boot] #{schema_file} loaded."
      end
    end

  ensure
    lock.flock(File::LOCK_UN)
  end
rescue => e
  Rails.logger.error "[boot] Database setup failed: #{e.message}"
  raise # Refuse to start with a broken schema.
end
