require "test_helper"

class ReportPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get report_pages_index_url
    assert_response :success
  end

  test "should get show" do
    get report_pages_show_url
    assert_response :success
  end
end
