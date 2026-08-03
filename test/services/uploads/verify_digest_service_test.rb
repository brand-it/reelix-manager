# frozen_string_literal: true

require 'test_helper'

class VerifyDigestServiceTest < ActiveSupport::TestCase
  test 'verifies matching digest' do
    content = 'test file content for digest verification'
    tmpfile = Tempfile.new(['test', '.mkv'])
    tmpfile.write(content)
    tmpfile.close

    expected_digest = Base64.strict_encode64(Digest::SHA256.digest(content))

    result = Uploads::VerifyDigestService.call(
      file_path: tmpfile.path,
      client_digest: expected_digest
    )

    assert_equal expected_digest, result
  ensure
    tmpfile&.unlink
  end

  test 'raises DigestMismatchError on mismatched digest' do
    content = 'test file content'
    tmpfile = Tempfile.new(['test', '.mkv'])
    tmpfile.write(content)
    tmpfile.close

    wrong_digest = Base64.strict_encode64(Digest::SHA256.digest('wrong content'))

    assert_raises(Uploads::VerifyDigestService::DigestMismatchError) do
      Uploads::VerifyDigestService.call(
        file_path: tmpfile.path,
        client_digest: wrong_digest
      )
    end
  ensure
    tmpfile&.unlink
  end

  test 'handles large file in chunks without loading entirely into memory' do
    # Create a 10 MB test file
    tmpfile = Tempfile.new(['large', '.mkv'])
    10.times { tmpfile.write('x' * (1024 * 1024)) }
    tmpfile.close

    expected = Digest::SHA256.file(tmpfile.path)
    expected_digest = Base64.strict_encode64(expected.digest)

    result = Uploads::VerifyDigestService.call(
      file_path: tmpfile.path,
      client_digest: expected_digest
    )

    assert_equal expected_digest, result
  ensure
    tmpfile&.unlink
  end

  test 'rejects digest of different length' do
    content = 'secret content'
    tmpfile = Tempfile.new(['test', '.mkv'])
    tmpfile.write(content)
    tmpfile.close

    correct_digest = Base64.strict_encode64(Digest::SHA256.digest(content))
    wrong_digest = correct_digest[0...-5] # Truncated

    assert_raises(Uploads::VerifyDigestService::DigestMismatchError) do
      Uploads::VerifyDigestService.call(
        file_path: tmpfile.path,
        client_digest: wrong_digest
      )
    end
  ensure
    tmpfile&.unlink
  end
end
