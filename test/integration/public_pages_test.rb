require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  test "visitors see the landing page" do
    get root_path
    assert_response :success
    assert_select "h1", /Swipez/
  end

  test "signed-in users land on the swipe deck" do
    sign_in users(:alice)
    get root_path
    assert_select ".deck"
  end

  test "app pages require authentication" do
    get dogs_path
    assert_redirected_to new_user_session_path
  end

  test "the web app manifest and service worker are public" do
    get pwa_manifest_path
    assert_response :success
    assert_equal "application/manifest+json", response.media_type
    manifest = JSON.parse(response.body)
    assert_equal "standalone", manifest["display"]
    assert(manifest["icons"].any? { |icon| icon["purpose"] == "maskable" })

    get pwa_service_worker_path
    assert_response :success
    assert_equal "text/javascript", response.media_type
    assert_includes response.body, "/offline"
  end

  test "offline page is public" do
    get offline_path
    assert_response :success
  end

  test "admin is restricted to admins" do
    sign_in users(:alice)
    get "/admin"
    assert_response :not_found
  end
end
