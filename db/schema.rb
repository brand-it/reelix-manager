# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 20_260_418_080_518) do
  create_table 'configs', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.text 'settings'
    t.string 'type', default: 'Config', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'error_entries', force: :cascade do |t|
    t.text 'backtrace', null: false
    t.datetime 'created_at', null: false
    t.string 'environment'
    t.string 'error_class', null: false
    t.text 'error_message', null: false
    t.string 'fingerprint', null: false
    t.text 'job_arguments'
    t.string 'job_class'
    t.string 'job_id'
    t.string 'job_queue'
    t.string 'request_method'
    t.text 'request_params'
    t.string 'request_path'
    t.string 'request_url'
    t.integer 'status', default: 0, null: false
    t.datetime 'updated_at', null: false
    t.string 'user_email'
    t.integer 'user_id'
    t.index ['created_at'], name: 'index_error_entries_on_created_at'
    t.index ['error_class'], name: 'index_error_entries_on_error_class'
    t.index ['fingerprint'], name: 'index_error_entries_on_fingerprint'
    t.index ['status'], name: 'index_error_entries_on_status'
  end

  create_table 'oauth_access_grants', force: :cascade do |t|
    t.integer 'application_id', null: false
    t.datetime 'created_at', null: false
    t.integer 'expires_in', null: false
    t.text 'redirect_uri', null: false
    t.integer 'resource_owner_id', null: false
    t.datetime 'revoked_at'
    t.string 'scopes', default: '', null: false
    t.string 'token', null: false
    t.index ['application_id'], name: 'index_oauth_access_grants_on_application_id'
    t.index ['resource_owner_id'], name: 'index_oauth_access_grants_on_resource_owner_id'
    t.index ['token'], name: 'index_oauth_access_grants_on_token', unique: true
  end

  create_table 'oauth_access_tokens', force: :cascade do |t|
    t.integer 'application_id', null: false
    t.datetime 'created_at', null: false
    t.integer 'expires_in'
    t.string 'previous_refresh_token', default: '', null: false
    t.string 'refresh_token'
    t.integer 'resource_owner_id'
    t.datetime 'revoked_at'
    t.string 'scopes'
    t.string 'token', null: false
    t.index ['application_id'], name: 'index_oauth_access_tokens_on_application_id'
    t.index ['refresh_token'], name: 'index_oauth_access_tokens_on_refresh_token', unique: true
    t.index ['resource_owner_id'], name: 'index_oauth_access_tokens_on_resource_owner_id'
    t.index ['token'], name: 'index_oauth_access_tokens_on_token', unique: true
  end

  create_table 'oauth_applications', force: :cascade do |t|
    t.boolean 'confidential', default: true, null: false
    t.datetime 'created_at', null: false
    t.text 'description'
    t.string 'name', null: false
    t.text 'redirect_uri', null: false
    t.string 'scopes', default: '', null: false
    t.string 'secret', null: false
    t.string 'uid', null: false
    t.datetime 'updated_at', null: false
    t.index ['uid'], name: 'index_oauth_applications_on_uid', unique: true
  end

  create_table 'oauth_device_grants', force: :cascade do |t|
    t.integer 'application_id', null: false
    t.datetime 'created_at', null: false
    t.string 'device_code', null: false
    t.integer 'expires_in', null: false
    t.datetime 'last_polling_at'
    t.integer 'resource_owner_id'
    t.string 'scopes', default: '', null: false
    t.string 'user_code'
    t.index ['application_id'], name: 'index_oauth_device_grants_on_application_id'
    t.index ['device_code'], name: 'index_oauth_device_grants_on_device_code', unique: true
    t.index ['resource_owner_id'], name: 'index_oauth_device_grants_on_resource_owner_id'
    t.index ['user_code'], name: 'index_oauth_device_grants_on_user_code', unique: true
  end

  create_table 'solid_cache_entries', force: :cascade do |t|
    t.integer 'byte_size', limit: 4, null: false
    t.datetime 'created_at', null: false
    t.binary 'key', limit: 1024, null: false
    t.integer 'key_hash', limit: 8, null: false
    t.binary 'value', limit: 536_870_912, null: false
    t.index ['byte_size'], name: 'index_solid_cache_entries_on_byte_size'
    t.index %w[key_hash byte_size], name: 'index_solid_cache_entries_on_key_hash_and_byte_size'
    t.index ['key_hash'], name: 'index_solid_cache_entries_on_key_hash', unique: true
  end

  create_table 'solid_queue_blocked_executions', force: :cascade do |t|
    t.string 'concurrency_key', null: false
    t.datetime 'created_at', null: false
    t.datetime 'expires_at', null: false
    t.bigint 'job_id', null: false
    t.integer 'priority', default: 0, null: false
    t.string 'queue_name', null: false
    t.index %w[concurrency_key priority job_id], name: 'index_solid_queue_blocked_executions_for_release'
    t.index %w[expires_at concurrency_key], name: 'index_solid_queue_blocked_executions_for_maintenance'
    t.index ['job_id'], name: 'index_solid_queue_blocked_executions_on_job_id', unique: true
  end

  create_table 'solid_queue_claimed_executions', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.bigint 'job_id', null: false
    t.bigint 'process_id'
    t.index ['job_id'], name: 'index_solid_queue_claimed_executions_on_job_id', unique: true
    t.index %w[process_id job_id], name: 'index_solid_queue_claimed_executions_on_process_id_and_job_id'
  end

  create_table 'solid_queue_failed_executions', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.text 'error'
    t.bigint 'job_id', null: false
    t.index ['job_id'], name: 'index_solid_queue_failed_executions_on_job_id', unique: true
  end

  create_table 'solid_queue_jobs', force: :cascade do |t|
    t.string 'active_job_id'
    t.text 'arguments'
    t.string 'class_name', null: false
    t.string 'concurrency_key'
    t.datetime 'created_at', null: false
    t.datetime 'finished_at'
    t.integer 'priority', default: 0, null: false
    t.string 'queue_name', null: false
    t.datetime 'scheduled_at'
    t.datetime 'updated_at', null: false
    t.index ['active_job_id'], name: 'index_solid_queue_jobs_on_active_job_id'
    t.index ['class_name'], name: 'index_solid_queue_jobs_on_class_name'
    t.index ['finished_at'], name: 'index_solid_queue_jobs_on_finished_at'
    t.index %w[queue_name finished_at], name: 'index_solid_queue_jobs_for_filtering'
    t.index %w[scheduled_at finished_at], name: 'index_solid_queue_jobs_for_alerting'
  end

  create_table 'solid_queue_pauses', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.string 'queue_name', null: false
    t.index ['queue_name'], name: 'index_solid_queue_pauses_on_queue_name', unique: true
  end

  create_table 'solid_queue_processes', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.string 'hostname'
    t.string 'kind', null: false
    t.datetime 'last_heartbeat_at', null: false
    t.text 'metadata'
    t.string 'name', null: false
    t.integer 'pid', null: false
    t.bigint 'supervisor_id'
    t.index ['last_heartbeat_at'], name: 'index_solid_queue_processes_on_last_heartbeat_at'
    t.index %w[name supervisor_id], name: 'index_solid_queue_processes_on_name_and_supervisor_id', unique: true
    t.index ['supervisor_id'], name: 'index_solid_queue_processes_on_supervisor_id'
  end

  create_table 'solid_queue_ready_executions', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.bigint 'job_id', null: false
    t.integer 'priority', default: 0, null: false
    t.string 'queue_name', null: false
    t.index ['job_id'], name: 'index_solid_queue_ready_executions_on_job_id', unique: true
    t.index %w[priority job_id], name: 'index_solid_queue_poll_all'
    t.index %w[queue_name priority job_id], name: 'index_solid_queue_poll_by_queue'
  end

  create_table 'solid_queue_recurring_executions', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.bigint 'job_id', null: false
    t.datetime 'run_at', null: false
    t.string 'task_key', null: false
    t.index ['job_id'], name: 'index_solid_queue_recurring_executions_on_job_id', unique: true
    t.index %w[task_key run_at], name: 'index_solid_queue_recurring_executions_on_task_key_and_run_at', unique: true
  end

  create_table 'solid_queue_recurring_tasks', force: :cascade do |t|
    t.text 'arguments'
    t.string 'class_name'
    t.string 'command', limit: 2048
    t.datetime 'created_at', null: false
    t.text 'description'
    t.string 'key', null: false
    t.integer 'priority', default: 0
    t.string 'queue_name'
    t.string 'schedule', null: false
    t.boolean 'static', default: true, null: false
    t.datetime 'updated_at', null: false
    t.index ['key'], name: 'index_solid_queue_recurring_tasks_on_key', unique: true
    t.index ['static'], name: 'index_solid_queue_recurring_tasks_on_static'
  end

  create_table 'solid_queue_scheduled_executions', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.bigint 'job_id', null: false
    t.integer 'priority', default: 0, null: false
    t.string 'queue_name', null: false
    t.datetime 'scheduled_at', null: false
    t.index ['job_id'], name: 'index_solid_queue_scheduled_executions_on_job_id', unique: true
    t.index %w[scheduled_at priority job_id], name: 'index_solid_queue_dispatch_all'
  end

  create_table 'solid_queue_semaphores', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.datetime 'expires_at', null: false
    t.string 'key', null: false
    t.datetime 'updated_at', null: false
    t.integer 'value', default: 1, null: false
    t.index ['expires_at'], name: 'index_solid_queue_semaphores_on_expires_at'
    t.index %w[key value], name: 'index_solid_queue_semaphores_on_key_and_value'
    t.index ['key'], name: 'index_solid_queue_semaphores_on_key', unique: true
  end

  create_table 'upload_sessions', id: :string, force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.string 'destination_path'
    t.text 'error_message'
    t.bigint 'file_size'
    t.string 'filename', null: false
    t.string 'mime_type'
    t.integer 'received_chunks', default: 0, null: false
    t.string 'status', default: 'pending', null: false
    t.integer 'total_chunks', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'users', force: :cascade do |t|
    t.boolean 'admin', default: false, null: false
    t.datetime 'created_at', null: false
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.datetime 'remember_created_at'
    t.datetime 'reset_password_sent_at'
    t.string 'reset_password_token'
    t.datetime 'updated_at', null: false
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
  end

  create_table 'video_blobs', force: :cascade do |t|
    t.string 'content_type'
    t.datetime 'created_at', null: false
    t.string 'edition'
    t.integer 'episode_last_number'
    t.integer 'episode_number'
    t.string 'episode_title'
    t.integer 'extra_type', default: 0, null: false
    t.integer 'extra_type_number'
    t.string 'filename', null: false
    t.string 'key', null: false
    t.integer 'media_type', default: 0, null: false
    t.boolean 'optimized', default: false, null: false
    t.integer 'part'
    t.string 'path_extension'
    t.boolean 'plex_version', default: false, null: false
    t.string 'poster_url'
    t.integer 'season_number'
    t.string 'title'
    t.integer 'tmdb_id'
    t.datetime 'updated_at', null: false
    t.integer 'year'
    t.index ['key'], name: 'index_video_blobs_on_key', unique: true
    t.index %w[media_type tmdb_id], name: 'index_video_blobs_on_media_type_and_tmdb_id'
    t.index ['tmdb_id'], name: 'index_video_blobs_on_tmdb_id'
  end

  add_foreign_key 'oauth_access_grants', 'oauth_applications', column: 'application_id'
  add_foreign_key 'oauth_access_tokens', 'oauth_applications', column: 'application_id'
  add_foreign_key 'oauth_device_grants', 'oauth_applications', column: 'application_id'
  add_foreign_key 'solid_queue_blocked_executions', 'solid_queue_jobs', column: 'job_id', on_delete: :cascade
  add_foreign_key 'solid_queue_claimed_executions', 'solid_queue_jobs', column: 'job_id', on_delete: :cascade
  add_foreign_key 'solid_queue_failed_executions', 'solid_queue_jobs', column: 'job_id', on_delete: :cascade
  add_foreign_key 'solid_queue_ready_executions', 'solid_queue_jobs', column: 'job_id', on_delete: :cascade
  add_foreign_key 'solid_queue_recurring_executions', 'solid_queue_jobs', column: 'job_id', on_delete: :cascade
  add_foreign_key 'solid_queue_scheduled_executions', 'solid_queue_jobs', column: 'job_id', on_delete: :cascade
end
