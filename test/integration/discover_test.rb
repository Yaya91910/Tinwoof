require "test_helper"

class DiscoverTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "the deck shows nearby dogs, closest first, never your own" do
    get root_path
    names = css_select(".swipe-card .swipe-card__name").map(&:text)
    assert_equal %w[Rex Luna], names
    assert_select ".swipe-card__meta", /à \d{3} m/
  end

  test "dogs already swiped leave the deck" do
    Swipe.create!(user: users(:alice), dog: dogs(:rex), liked: true)
    get root_path
    assert_select ".swipe-card__name", text: "Rex", count: 0
  end

  test "liking returns whether it is a match" do
    post swipes_path, params: { dog_id: dogs(:luna).id, liked: true }, as: :json
    assert_response :success
    assert_equal false, response.parsed_body["match"]
    assert_nil response.parsed_body["chatroom_url"]

    Swipe.create!(user: users(:carol), dog: dogs(:milo), liked: true)
    post swipes_path, params: { dog_id: dogs(:ollie).id, liked: true }, as: :json
    assert response.parsed_body["match"]
    assert_match %r{/chatrooms/\d+}, response.parsed_body["chatroom_url"]
  end

  test "passing is recorded" do
    assert_difference -> { users(:alice).swipes.where(liked: false).count } do
      post swipes_path, params: { dog_id: dogs(:rex).id, liked: false }, as: :json
    end
  end

  test "you cannot swipe your own dog" do
    post swipes_path, params: { dog_id: dogs(:milo).id, liked: true }, as: :json
    assert_response :not_found
  end
end

class DiscoverEngagementTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "dogs whose owner already liked us come first, with a banner" do
    Swipe.record!(user: users(:carol), dog: dogs(:milo), liked: true, superlike: true)
    get root_path

    names = css_select(".swipe-card .swipe-card__name").map(&:text)
    # Carol's dogs first (even Ollie, far beyond the radius), then the nearby ones.
    assert_equal %w[Luna Ollie], names.first(2).sort
    assert_equal "Rex", names.last
    assert_select ".swipe-card--super .swipe-card__admirer", /Carol a super-liké Milo/
    assert_select ".chip--hot", /1/
  end

  test "super liking returns the remaining quota" do
    post swipes_path, params: { dog_id: dogs(:rex).id, liked: true, superlike: true }, as: :json
    assert_equal Swipe::SUPERLIKES_PER_DAY - 1, response.parsed_body["superlikes_left"]
  end

  test "undo brings the latest dog back" do
    post swipes_path, params: { dog_id: dogs(:rex).id, liked: false }, as: :json
    delete undo_swipes_path, as: :json
    assert_response :success
    assert_equal dogs(:rex).id, response.parsed_body["dog_id"]

    delete undo_swipes_path, as: :json
    assert_response :unprocessable_entity
  end

  test "liking from a dog's profile" do
    post swipes_path, params: { dog_id: dogs(:rex).id, liked: true }
    assert_redirected_to dog_path(dogs(:rex))
    follow_redirect!
    assert_select ".crush__done", /Vous avez craqué pour Rex/
  end

  test "a like that matches from a dog's profile opens the conversation" do
    Swipe.record!(user: users(:carol), dog: dogs(:milo), liked: true)
    post swipes_path, params: { dog_id: dogs(:luna).id, liked: true }
    assert_redirected_to %r{/chatrooms/\d+}
  end

  test "the empty deck offers to widen the radius" do
    [dogs(:rex), dogs(:luna), dogs(:ollie)].each { |dog| Swipe.create!(user: users(:alice), dog: dog, liked: false) }
    get root_path
    assert_select "form[action='#{profile_path}'] button", "Passer à 25 km"

    patch profile_path, params: { user: { search_radius_km: 25 }, return_to: "discover" }
    assert_redirected_to root_path
  end

  test "the profile shows admirers and what is left to complete" do
    Swipe.record!(user: users(:bob), dog: dogs(:milo), liked: true)
    get profile_path
    assert_select ".admirer__name", "Bob"
    assert_select ".completion__title", /40/
  end
end
