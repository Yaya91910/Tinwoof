require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "full name capitalizes without mangling compound names" do
    user = User.new(first_name: "guillaume", last_name: "d'Aoust")
    assert_equal "Guillaume D'Aoust", user.full_name
  end

  test "update_location rounds coordinates to protect privacy" do
    user = users(:bob)
    assert user.update_location(latitude: "48.856613", longitude: "2.352222", label: "Paris 4e")

    assert_equal 48.857, user.latitude
    assert_equal 2.352, user.longitude
    assert_equal "Paris 4e", user.address
    assert user.located?
    assert_in_delta Time.current, user.located_at, 5.seconds
  end

  test "update_location rejects garbage and out-of-range coordinates" do
    user = users(:bob)
    assert_not user.update_location(latitude: "north", longitude: "2.35")
    assert_not user.update_location(latitude: "123", longitude: "2.35")
    assert_not user.reload.located?
  end

  test "forget_location! clears the position" do
    user = users(:alice)
    user.forget_location!
    assert_not user.reload.located?
    assert_nil user.coordinates
  end

  test "search radius must be one of the offered values" do
    user = users(:alice)
    user.search_radius_km = 7
    assert_not user.valid?
  end

  test "counts unread messages written by others" do
    assert_equal 1, users(:alice).unread_messages_count
    assert_equal 0, users(:bob).unread_messages_count
  end

  test "admirers are the owners who liked one of our dogs, super likes first" do
    Swipe.record!(user: users(:bob), dog: dogs(:milo), liked: true)
    Swipe.record!(user: users(:carol), dog: dogs(:milo), liked: true, superlike: true)

    admirers = users(:alice).admirer_likes
    assert_equal [users(:carol).id, users(:bob).id], admirers.keys
    assert admirers[users(:carol).id].superlike?
  end

  test "profile completion counts the filled steps" do
    alice = users(:alice)
    assert_equal 40, alice.profile_completion # dog + location, no photo, no bio, no dog photo
    alice.update!(bio: "Balades au canal")
    assert_equal 60, alice.profile_completion
  end

  test "destroying a user removes their chatrooms and dogs" do
    assert_difference -> { Chatroom.count } => -1, -> { Dog.count } => -1 do
      users(:bob).destroy!
    end
  end
end
