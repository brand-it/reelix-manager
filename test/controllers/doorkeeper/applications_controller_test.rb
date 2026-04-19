# frozen_string_literal: true

require 'test_helper'

module Doorkeeper
  class ApplicationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, admin: true)
      @user  = create(:user, admin: false)
      @oauth_app = Doorkeeper::Application.create!(
        name: 'Test App',
        uid: 'test-app-uid',
        redirect_uri: '',
        scopes: 'search upload',
        confidential: false
      )
    end

    teardown do
      Doorkeeper::Application.delete_all
    end

    # ---------------------------------------------------------------------------
    # Authentication / authorization
    # ---------------------------------------------------------------------------

    test 'unauthenticated GET index redirects to sign-in' do
      get '/oauth/applications'
      assert_redirected_to new_user_session_path
    end

    test 'non-admin GET index redirects away' do
      sign_in @user
      get '/oauth/applications'
      assert_response :redirect
      assert_not_equal '/oauth/applications', response.location
    end

    test 'admin GET index returns 200' do
      sign_in @admin
      get '/oauth/applications'
      assert_response :success
    end

    # ---------------------------------------------------------------------------
    # Layout — full nav bar rendered (not Doorkeeper's stripped-down layout)
    # ---------------------------------------------------------------------------

    test 'applications pages use the application layout with full nav bar' do
      sign_in @admin
      get '/oauth/applications'
      assert_select 'nav.navbar'
      assert_select 'a.navbar-brand', text: /Reelix Manager/i
      assert_select 'a[href=?]', '/docs/api', text: /API Docs/i
      assert_select 'a[href=?]', '/devices',  text: /Devices/i
    end

    # ---------------------------------------------------------------------------
    # GET index
    # ---------------------------------------------------------------------------

    test 'GET index lists application names and client IDs' do
      sign_in @admin
      get '/oauth/applications'
      assert_select 'td code', text: 'test-app-uid'
      assert_match 'Test App', response.body
    end

    test 'GET index shows scope badges' do
      sign_in @admin
      get '/oauth/applications'
      assert_select '.badge', text: 'search'
      assert_select '.badge', text: 'upload'
    end

    test 'GET index shows New Application button' do
      sign_in @admin
      get '/oauth/applications'
      assert_select 'a[href=?]', new_oauth_application_path
    end

    # ---------------------------------------------------------------------------
    # GET new
    # ---------------------------------------------------------------------------

    test 'GET new returns 200' do
      sign_in @admin
      get new_oauth_application_path
      assert_response :success
    end

    test 'GET new form has a name field' do
      sign_in @admin
      get new_oauth_application_path
      assert_select 'input[name=?]', 'doorkeeper_application[name]'
    end

    test 'GET new form has a uid field for custom client ID' do
      sign_in @admin
      get new_oauth_application_path
      assert_select 'input[name=?]', 'doorkeeper_application[uid]'
    end

    test 'GET new form has scope checkboxes not a text field' do
      sign_in @admin
      get new_oauth_application_path
      assert_select 'input[type=checkbox][name=?]', 'doorkeeper_application[scopes][]'
      assert_select 'input[type=text][name=?]',     'doorkeeper_application[scopes]', count: 0
    end

    test 'GET new form has an all scope checkbox' do
      sign_in @admin
      get new_oauth_application_path
      assert_select 'input[type=checkbox][value=all]'
    end

    test 'GET new form has a search scope checkbox' do
      sign_in @admin
      get new_oauth_application_path
      assert_select 'input[type=checkbox][value=search]'
    end

    test 'GET new form has an upload scope checkbox' do
      sign_in @admin
      get new_oauth_application_path
      assert_select 'input[type=checkbox][value=upload]'
    end

    # ---------------------------------------------------------------------------
    # POST create
    # ---------------------------------------------------------------------------

    test 'POST create with valid params creates application and redirects' do
      sign_in @admin
      assert_difference 'Doorkeeper::Application.count', 1 do
        post '/oauth/applications', params: {
          doorkeeper_application: {
            name: 'New Client',
            redirect_uri: '',
            scopes: ['search'],
            confidential: '0'
          }
        }
      end
      assert_response :redirect
    end

    test 'POST create saves scopes as space-separated string from checkboxes' do
      sign_in @admin
      post '/oauth/applications', params: {
        doorkeeper_application: {
          name: 'Scoped App',
          redirect_uri: '',
          scopes: %w[search upload],
          confidential: '0'
        }
      }
      created = Doorkeeper::Application.find_by(name: 'Scoped App')
      assert_not_nil created
      assert_includes created.scopes.to_a, 'search'
      assert_includes created.scopes.to_a, 'upload'
    end

    test 'POST create with custom uid saves that uid' do
      sign_in @admin
      post '/oauth/applications', params: {
        doorkeeper_application: {
          name: 'Custom ID App',
          uid: 'my-custom-client',
          redirect_uri: '',
          scopes: ['all'],
          confidential: '0'
        }
      }
      created = Doorkeeper::Application.find_by(name: 'Custom ID App')
      assert_not_nil created
      assert_equal 'my-custom-client', created.uid
    end

    test 'POST create without name re-renders new form' do
      sign_in @admin
      assert_no_difference 'Doorkeeper::Application.count' do
        post '/oauth/applications', params: {
          doorkeeper_application: {
            name: '',
            redirect_uri: '',
            scopes: [],
            confidential: '0'
          }
        }
      end
      assert_response :success
      assert_select 'input[name=?]', 'doorkeeper_application[name]'
    end

    # ---------------------------------------------------------------------------
    # GET show
    # ---------------------------------------------------------------------------

    test 'GET show returns 200' do
      sign_in @admin
      get oauth_application_path(@oauth_app)
      assert_response :success
    end

    test 'GET show displays the application name in the title (not raw %{name})' do
      sign_in @admin
      get oauth_application_path(@oauth_app)
      assert_match 'Test App', response.body
      assert_no_match '%{name}', response.body
    end

    test 'GET show displays the client ID' do
      sign_in @admin
      get oauth_application_path(@oauth_app)
      assert_select 'code', text: 'test-app-uid'
    end

    test 'GET show displays scopes as badges' do
      sign_in @admin
      get oauth_application_path(@oauth_app)
      assert_select '.badge', text: 'search'
      assert_select '.badge', text: 'upload'
    end

    test 'GET show has a danger zone with delete button' do
      sign_in @admin
      get oauth_application_path(@oauth_app)
      assert_match 'Danger zone', response.body
      assert_select 'form[action=?]', oauth_application_path(@oauth_app)
    end

    # ---------------------------------------------------------------------------
    # GET edit
    # ---------------------------------------------------------------------------

    test 'GET edit returns 200' do
      sign_in @admin
      get edit_oauth_application_path(@oauth_app)
      assert_response :success
    end

    test 'GET edit pre-checks the existing scopes' do
      sign_in @admin
      get edit_oauth_application_path(@oauth_app)
      assert_select 'input[type=checkbox][value=search][checked]'
      assert_select 'input[type=checkbox][value=upload][checked]'
    end

    test 'GET edit does not show the uid field' do
      sign_in @admin
      get edit_oauth_application_path(@oauth_app)
      assert_select 'input[name=?]', 'doorkeeper_application[uid]', count: 0
    end

    # ---------------------------------------------------------------------------
    # PATCH update
    # ---------------------------------------------------------------------------

    test 'PATCH update changes the application name' do
      sign_in @admin
      patch oauth_application_path(@oauth_app), params: {
        doorkeeper_application: {
          name: 'Renamed App',
          redirect_uri: '',
          scopes: ['search'],
          confidential: '0'
        }
      }
      assert_response :redirect
      assert_equal 'Renamed App', @oauth_app.reload.name
    end

    test 'PATCH update saves updated scopes from checkboxes' do
      sign_in @admin
      patch oauth_application_path(@oauth_app), params: {
        doorkeeper_application: {
          name: @oauth_app.name,
          redirect_uri: '',
          scopes: ['upload'],
          confidential: '0'
        }
      }
      @oauth_app.reload
      assert_includes @oauth_app.scopes.to_a, 'upload'
      assert_not_includes @oauth_app.scopes.to_a, 'search'
    end

    test 'PATCH update with no scopes saves empty string' do
      sign_in @admin
      patch oauth_application_path(@oauth_app), params: {
        doorkeeper_application: {
          name: @oauth_app.name,
          redirect_uri: '',
          scopes: [],
          confidential: '0'
        }
      }
      assert_equal '', @oauth_app.reload.scopes.to_s
    end

    # ---------------------------------------------------------------------------
    # DELETE destroy
    # ---------------------------------------------------------------------------

    test 'DELETE destroy removes the application and redirects to index' do
      sign_in @admin
      assert_difference 'Doorkeeper::Application.count', -1 do
        delete oauth_application_path(@oauth_app)
      end
      assert_redirected_to oauth_applications_path
    end
  end
end
