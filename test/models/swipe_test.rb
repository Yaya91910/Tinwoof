require "test_helper"

class SwipeTest < ActiveSupport::TestCase
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

  test "cannot swipe one's own dog" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Swipe.record!(user: users(:bob), dog: dogs(:rex), liked: true)
    end
  end
end
