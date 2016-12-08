# Redmine - project management software
# Copyright (C) 2006-2016  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class VersionsControllerTest < Redmine::ControllerTest
  fixtures :projects, :versions, :issues, :users, :roles, :members,
           :member_roles, :enabled_modules, :issue_statuses,
           :issue_categories, :enumerations

  def setup
    User.current = nil
  end

  def test_index
    get :index, :params => {:project_id => 1}
    assert_response :success

    # Version with no date set appears
    assert_select 'h3', :text => Version.find(3).name
    # Completed version doesn't appear
    assert_select 'h3', :text => Version.find(1).name, :count => 0

    # Context menu on issues
    assert_select "script", :text => Regexp.new(Regexp.escape("contextMenuInit('/issues/context_menu')"))
    assert_select "div#sidebar" do
      # Links to versions anchors
      assert_select 'a[href=?]', '#2.0'
      # Links to completed versions in the sidebar
      assert_select 'a[href=?]', '/versions/1'
    end
  end

  def test_index_with_completed_versions
    get :index, :params => {:project_id => 1, :completed => 1}
    assert_response :success

    # Version with no date set appears
    assert_select 'h3', :text => Version.find(3).name
    # Completed version appears
    assert_select 'h3', :text => Version.find(1).name
  end

  def test_index_with_tracker_ids
    (1..3).each do |tracker_id|
      Issue.generate! :project_id => 1, :fixed_version_id => 3, :tracker_id => tracker_id
    end
    get :index, :params => {:project_id => 1, :tracker_ids => [1, 3]}
    assert_response :success
    assert_select 'a.issue.tracker-1'
    assert_select 'a.issue.tracker-2', 0
    assert_select 'a.issue.tracker-3'
  end

  def test_index_showing_subprojects_versions
    @subproject_version = Version.create!(:project => Project.find(3), :name => "Subproject version")
    get :index, :params => {:project_id => 1, :with_subprojects => 1}
    assert_response :success

    # Shared version
    assert_select 'h3', :text => Version.find(4).name
    # Subproject version
    assert_select 'h3', :text => /Subproject version/
  end

  def test_index_should_prepend_shared_versions
    get :index, :params => {:project_id => 1}
    assert_response :success

    assert_select '#sidebar' do
      assert_select 'a[href=?]', '#2.0', :text => '2.0'
      assert_select 'a[href=?]', '#subproject1-2.0', :text => 'eCookbook Subproject 1 - 2.0'
    end
    assert_select '#content' do
      assert_select 'a[name=?]', '2.0', :text => '2.0'
      assert_select 'a[name=?]', 'subproject1-2.0', :text => 'eCookbook Subproject 1 - 2.0'
    end
  end

  def test_show
    get :show, :params => {:id => 2}
    assert_response :success

    assert_select 'h2', :text => /1.0/
  end

  def test_show_should_link_to_spent_time_on_version
    version = Version.generate!
    issue = Issue.generate(:fixed_version => version)
    TimeEntry.generate!(:issue => issue, :hours => 7.2)

    get :show, :params => {:id => version.id}
    assert_response :success

    assert_select '.total-hours', :text => '7.20 hours'
    assert_select '.total-hours a[href=?]', "/projects/ecookbook/time_entries?issue.fixed_version_id=#{version.id}&set_filter=1"
  end

  def test_show_should_display_nil_counts
    with_settings :default_language => 'en' do
      get :show, :params => {:id => 2, :status_by => 'category'}
      assert_response :success
      assert_select 'div#status_by' do
        assert_select 'select[name=status_by]' do
          assert_select 'option[value=category][selected=selected]'
        end
        assert_select 'a', :text => 'none'
      end
    end
  end

  def test_new
    @request.session[:user_id] = 2
    get :new, :params => {:project_id => '1'}
    assert_response :success
    assert_select 'input[name=?]', 'version[name]'
    assert_select 'select[name=?]', 'version[status]', false
  end

  def test_new_from_issue_form
    @request.session[:user_id] = 2
    xhr :get, :new, :params => {:project_id => '1'}
    assert_response :success
    assert_equal 'text/javascript', response.content_type
  end

  def test_create
    @request.session[:user_id] = 2 # manager
    assert_difference 'Version.count' do
      post :create, :params => {:project_id => '1', :version => {:name => 'test_add_version'}}
    end
    assert_redirected_to '/projects/ecookbook/settings/versions'
    version = Version.find_by_name('test_add_version')
    assert_not_nil version
    assert_equal 1, version.project_id
  end

  def test_create_from_issue_form
    @request.session[:user_id] = 2
    assert_difference 'Version.count' do
      xhr :post, :create, :params => {:project_id => '1', :version => {:name => 'test_add_version_from_issue_form'}}
    end
    version = Version.find_by_name('test_add_version_from_issue_form')
    assert_not_nil version
    assert_equal 1, version.project_id

    assert_response :success
    assert_equal 'text/javascript', response.content_type
    assert_include 'test_add_version_from_issue_form', response.body
  end

  def test_create_from_issue_form_with_failure
    @request.session[:user_id] = 2
    assert_no_difference 'Version.count' do
      xhr :post, :create, :params => {:project_id => '1', :version => {:name => ''}}
    end
    assert_response :success
    assert_equal 'text/javascript', response.content_type
  end

  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :params => {:id => 2}
    assert_response :success
    version = Version.find(2)

    assert_select 'select[name=?]', 'version[status]' do
      assert_select 'option[value=?][selected="selected"]', version.status
    end
    assert_select 'input[name=?][value=?]', 'version[name]', version.name
  end

  def test_close_completed
    Version.update_all("status = 'open'")
    @request.session[:user_id] = 2
    put :close_completed, :params => {:project_id => 'ecookbook'}
    assert_redirected_to :controller => 'projects', :action => 'settings',
                         :tab => 'versions', :id => 'ecookbook'
    assert_not_nil Version.find_by_status('closed')
  end

  def test_post_update
    @request.session[:user_id] = 2
    put :update, :params => {
      :id => 2,
      :version => {
        :name => 'New version name',
        :effective_date => Date.today.strftime("%Y-%m-%d")
      }
    }
    assert_redirected_to :controller => 'projects', :action => 'settings',
                         :tab => 'versions', :id => 'ecookbook'
    version = Version.find(2)
    assert_equal 'New version name', version.name
    assert_equal Date.today, version.effective_date
  end

  def test_post_update_with_validation_failure
    @request.session[:user_id] = 2
    put :update, :params => {
      :id => 2,
      :version => {
        :name => '',
        :effective_date => Date.today.strftime("%Y-%m-%d")
      }
    }
    assert_response :success
    assert_select_error /Name cannot be blank/
  end

  def test_destroy
    @request.session[:user_id] = 2
    assert_difference 'Version.count', -1 do
      delete :destroy, :params => {:id => 3}
    end
    assert_redirected_to :controller => 'projects', :action => 'settings',
                         :tab => 'versions', :id => 'ecookbook'
    assert_nil Version.find_by_id(3)
  end

  def test_destroy_version_in_use_should_fail
    @request.session[:user_id] = 2
    assert_no_difference 'Version.count' do
      delete :destroy, :params => {:id => 2}
    end
    assert_redirected_to :controller => 'projects', :action => 'settings',
                         :tab => 'versions', :id => 'ecookbook'
    assert flash[:error].match(/Unable to delete version/)
    assert Version.find_by_id(2)
  end

  def test_issue_status_by
    xhr :get, :status_by, :params => {:id => 2}
    assert_response :success
  end

  def test_issue_status_by_status
    xhr :get, :status_by, :params => {:id => 2, :status_by => 'status'}
    assert_response :success
    assert_include 'Assigned', response.body
    assert_include 'Closed', response.body
  end
end