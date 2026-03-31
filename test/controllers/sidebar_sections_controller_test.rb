require "test_helper"

class SidebarSectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get sidebar_sections_show_url
    assert_response :success
  end
end
