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
    assert_equal({ "match" => false, "chatroom_url" => nil }, response.parsed_body)

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
