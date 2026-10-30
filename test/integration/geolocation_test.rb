require "test_helper"

class GeolocationTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:bob) }

  test "the browser position is stored, rounded" do
    patch location_path, params: { location: { latitude: 48.86412, longitude: 2.37589, label: "Paris 11e" } }, as: :json
    assert_response :no_content

    bob = users(:bob).reload
    assert_equal [48.864, 2.376], bob.coordinates
    assert_equal "Paris 11e", bob.address
  end

  test "invalid positions are rejected" do
    patch location_path, params: { location: { latitude: "abc", longitude: 2.37 } }, as: :json
    assert_response :unprocessable_entity
  end

  test "the position can be erased" do
    users(:bob).update_location(latitude: 48.86, longitude: 2.37)
    delete location_path
    assert_redirected_to profile_path
    assert_not users(:bob).reload.located?
  end

  test "the map streams dogs inside the visible area as GeoJSON" do
    get map_path(format: :json, bbox: "2.2,48.8,2.5,48.9")
    assert_response :success

    names = response.parsed_body["features"].map { |feature| feature["properties"]["name"] }
    assert_includes names, "Rex"
    assert_not_includes names, "Ollie"
    assert_equal [2.3746, 48.8636], response.parsed_body["features"].find { |f| f["properties"]["name"] == "Rex" }["geometry"]["coordinates"]
  end

  test "the discovery radius is a profile preference" do
    patch profile_path, params: { user: { search_radius_km: 50 } }
    assert_redirected_to profile_path
    assert_equal 50, users(:bob).reload.search_radius_km
  end
end
