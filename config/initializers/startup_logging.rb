separator = "=" * 60

Rails.logger.info(separator)
version = File.read(Rails.root.join("VERSION")).strip
Rails.logger.info("Reelix Manager v#{version} starting")
Rails.logger.info(separator)
Rails.logger.info("Environment : #{Rails.env}")
Rails.logger.info("Ruby        : #{RUBY_VERSION} (#{RUBY_PLATFORM})")
Rails.logger.info("Rails       : #{Rails::VERSION::STRING}")
Rails.logger.info("PID         : #{$$}")
Rails.logger.info("Hostname    : #{Socket.gethostname}")
Rails.logger.info("Threads     : #{ENV.fetch('RAILS_MAX_THREADS', 5)}")
Rails.logger.info("Cache store : #{Rails.cache.class.name}")
Rails.logger.info("Job adapter : #{ActiveJob::Base.queue_adapter_name}")

begin
  db = ActiveRecord::Base.connection_db_config
  Rails.logger.info("Database    : #{db.adapter} — #{db.database}")
rescue StandardError => e
  Rails.logger.info("Database    : not available yet (#{e.class})")
end

Rails.logger.info(separator)
