require "test_helper"

class SwipeTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  include Turbo::Streams::StreamName
  test "a one-sided like is not a match" do
    assert_nil Swipe.record!(user: users(:carol), dog: dogs(:rex), liked: true)
  end

  test "a like completing a mutual interest opens a chatroom" do
    Swipe.record!(user: users(:bob), dog: dogs(:luna), liked: true)

    assert_difference -> { Chatroom.count } do
      chatroom = Swipe.record!(user: users(:carol), dog: dogs(:rex), liked: true)
      assert chatroom.participant?(users(:bob))
      assert chatroom.participant?(users(:carol))
    end
  end

  test "a match reuses an existing chatroom" do
    Swipe.record!(user: users(:bob), dog: dogs(:milo), liked: true)

    assert_no_difference -> { Chatroom.count } do
      assert_equal chatrooms(:alice_bob), Swipe.record!(user: users(:alice), dog: dogs(:rex), liked: true)
    end
  end

  test "a pass never matches" do
    Swipe.record!(user: users(:bob), dog: dogs(:luna), liked: true)
    assert_nil Swipe.record!(user: users(:carol), dog: dogs(:rex), liked: false)
  end

  test "swiping again updates the previous decision" do
    Swipe.record!(user: users(:carol), dog: dogs(:rex), liked: false)
    Swipe.record!(user: users(:carol), dog: dogs(:rex), liked: true)

    assert_equal 1, Swipe.where(user: users(:carol), dog: dogs(:rex)).count
    assert Swipe.find_by(user: users(:carol), dog: dogs(:rex)).liked?
  end

  test "a super like is a like that also completes matches" do
    Swipe.record!(user: users(:bob), dog: dogs(:luna), liked: true)
    assert Swipe.record!(user: users(:carol), dog: dogs(:rex), liked: true, superlike: true)
    assert Swipe.find_by(user: users(:carol), dog: dogs(:rex)).superlike?
  end

  test "super likes are limited per day" do
    user = users(:alice)
    dogs = [dogs(:rex), dogs(:luna), dogs(:ollie)]
    dogs.each { |dog| Swipe.record!(user: user, dog: dog, liked: true, superlike: true) }
    assert_equal 0, user.superlikes_left_today

    extra = users(:carol).dogs.create!(name: "Plume", gender: "female", breed: "Basset", latitude: 48.86, longitude: 2.35)
    assert_raises(ActiveRecord::RecordInvalid) { Swipe.record!(user: user, dog: extra, liked: true, superlike: true) }

    travel 1.day do
      assert_equal Swipe::SUPERLIKES_PER_DAY, user.superlikes_left_today
    end
  end

  test "passing never records a super like" do
    Swipe.record!(user: users(:alice), dog: dogs(:rex), liked: false, superlike: true)
    assert_not Swipe.find_by(user: users(:alice), dog: dogs(:rex)).superlike?
  end

  test "the other owner is told about the match live" do
    Swipe.record!(user: users(:bob), dog: dogs(:luna), liked: true)
    assert_broadcasts(stream_name_from([users(:bob), :inbox]), 1) do
      Swipe.record!(user: users(:carol), dog: dogs(:rex), liked: true)
    end
  end

  test "undo takes back the latest decision, but never a match" do
    Swipe.record!(user: users(:alice), dog: dogs(:luna), liked: false)
    travel 1.second
    Swipe.record!(user: users(:alice), dog: dogs(:ollie), liked: true)
    assert_equal dogs(:ollie), Swipe.undo_last!(users(:alice)).dog
    assert_not Swipe.exists?(user: users(:alice), dog: dogs(:ollie))

    Swipe.record!(user: users(:bob), dog: dogs(:milo), liked: true)
    travel 1.second
    Swipe.record!(user: users(:alice), dog: dogs(:rex), liked: true)
    assert_nil Swipe.undo_last!(users(:alice))
  end

  test "cannot swipe one's own dog" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Swipe.record!(user: users(:bob), dog: dogs(:rex), liked: true)
    end
  end
end
