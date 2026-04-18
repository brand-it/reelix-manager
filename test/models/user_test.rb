# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'valid with email and password' do
    user = build(:user)
    assert user.valid?
  end

  test 'invalid without email' do
    user = build(:user, email: nil)
    assert_not user.valid?
  end

  test 'invalid with duplicate email' do
    create(:user, email: 'dup@example.com')
    user = build(:user, email: 'dup@example.com')
    assert_not user.valid?
  end

  test 'admin? returns true when admin flag is set' do
    assert build(:user, admin: true).admin?
  end

  test 'admin? returns false by default' do
    assert_not build(:user).admin?
  end
end
