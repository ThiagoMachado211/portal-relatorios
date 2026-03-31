require "test_helper"

class Admin::SidebarSectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_sidebar_sections_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_sidebar_sections_show_url
    assert_response :success
  end

  test "should get new" do
    get admin_sidebar_sections_new_url
    assert_response :success
  end

  test "should get edit" do
    get admin_sidebar_sections_edit_url
    assert_response :success
  end
end
