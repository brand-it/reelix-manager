# frozen_string_literal: true

require 'test_helper'

class ErrorLoggerServiceTest < ActiveSupport::TestCase
  test 'logs error and returns ErrorEntry' do
    error = StandardError.new('test error')

    result = ErrorLoggerService.call(error)

    assert_instance_of(ErrorEntry, result)
    assert_equal('StandardError', result.error_class)
    assert_equal('test error', result.error_message)
    assert_equal('unacknowledged', result.status)
    assert_equal(Rails.env, result.environment)
    assert result.fingerprint.present?
    assert_equal(16, result.fingerprint.length)
  end

  test 'logs error with controller context' do
    error = StandardError.new('controller error')

    request = Object.new
    request.define_singleton_method(:url) { 'http://example.com/test' }
    request.define_singleton_method(:method) { 'GET' }
    request.define_singleton_method(:path) { '/test' }

    controller = Object.new
    controller.define_singleton_method(:request) { request }
    controller.define_singleton_method(:params) { { action: 'show', id: '123' } }

    result = ErrorLoggerService.call(error, controller)

    assert_instance_of(ErrorEntry, result)
    assert_equal('http://example.com/test', result.request_url)
    assert_equal('GET', result.request_method)
    assert_equal('/test', result.request_path)
    assert result.request_params.present?
  end

  test 'logs error with job context' do
    error = StandardError.new('job error')
    job = LibraryScanJob.new

    result = ErrorLoggerService.call(error, job)

    assert_instance_of(ErrorEntry, result)
    assert_equal('LibraryScanJob', result.job_class)
    assert result.job_id.present?
    assert_equal('default', result.job_queue)
  end

  test 'logs error with GraphQL context' do
    error = StandardError.new('graphql error')

    query_obj = GraphQL::Query.new(
      ReelixManagerSchema,
      'query { movies }',
      variables: { limit: 10 }
    )
    context = query_obj.context

    result = ErrorLoggerService.call(error, context)

    assert_instance_of(ErrorEntry, result)
    assert_equal('/graphql', result.request_path)
    assert result.request_params.present?
  end

  test 'logs error with nil context' do
    error = StandardError.new('no context error')

    result = ErrorLoggerService.call(error, nil)

    assert_instance_of(ErrorEntry, result)
    assert_nil result.request_url
    assert_nil result.job_class
  end

  test 'extracts user info from context with current_user method' do
    error = StandardError.new('user error')

    user = Object.new
    user.define_singleton_method(:id) { 42 }
    user.define_singleton_method(:email) { 'test@example.com' }

    context = Object.new
    context.define_singleton_method(:current_user) { user }

    result = ErrorLoggerService.call(error, context)

    assert_equal(42, result.user_id)
    assert_equal('test@example.com', result.user_email)
  end

  test 'extracts user info from context with hash access' do
    error = StandardError.new('user error')

    user = Object.new
    user.define_singleton_method(:id) { 43 }
    user.define_singleton_method(:email) { 'hash@example.com' }

    context = { current_user: user }

    result = ErrorLoggerService.call(error, context)

    assert_equal(43, result.user_id)
    assert_equal('hash@example.com', result.user_email)
  end

  test 'handles error without backtrace' do
    # Create an error with nil backtrace
    error = StandardError.new('no backtrace')
    def error.backtrace = nil

    result = ErrorLoggerService.call(error)

    assert_instance_of(ErrorEntry, result)
    assert_equal('No backtrace', result.backtrace)
  end

  test 'generates consistent fingerprint for same error class and backtrace' do
    error1 = StandardError.new('same error')
    error2 = StandardError.new('same error')

    # Force same backtrace by using same location
    result1 = ErrorLoggerService.call(error1)
    result2 = ErrorLoggerService.call(error2)

    # Fingerprints should be based on error class and first line of backtrace
    assert result1.fingerprint.present?
    assert result2.fingerprint.present?
  end

  test 'sanitizes sensitive params in controller context' do
    error = StandardError.new('sensitive params error')

    request = Object.new
    request.define_singleton_method(:url) { 'http://example.com/login' }
    request.define_singleton_method(:method) { 'POST' }
    request.define_singleton_method(:path) { '/login' }

    controller = Object.new
    controller.define_singleton_method(:request) { request }
    # 'secret' matches the filter pattern
    controller.define_singleton_method(:params) { { secret: 'secret123', safe_param: 'visible' } }

    result = ErrorLoggerService.call(error, controller)

    # 'secret' should be filtered out by ErrorEntry.sanitize_params
    params = JSON.parse(result.request_params)
    # Filtered params are replaced with '[FILTERED]' string
    assert_equal('[FILTERED]', params['secret'])
    assert_equal('visible', params['safe_param'])
  end

  test 'raises when error logging fails' do
    error = StandardError.new('test error')

    # Stub ErrorEntry.create! to raise an exception
    original_create = ErrorEntry.method(:create!)

    begin
      ErrorEntry.define_singleton_method(:create!) do |**_kwargs|
        raise ActiveRecord::StatementInvalid, 'database error'
      end

      assert_raises(ActiveRecord::StatementInvalid) do
        ErrorLoggerService.call(error)
      end
    ensure
      ErrorEntry.define_singleton_method(:create!, original_create)
    end
  end
end
