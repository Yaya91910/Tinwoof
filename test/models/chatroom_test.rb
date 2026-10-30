require "test_helper"

class ChatroomTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  include Turbo::Streams::StreamName
  test "between finds the chatroom whatever the order of participants" do
    assert_equal chatrooms(:alice_bob), Chatroom.between(users(:bob), users(:alice))
    assert_equal chatrooms(:alice_bob), Chatroom.between(users(:alice), users(:bob))
  end

  test "between creates the chatroom when missing" do
    assert_difference -> { Chatroom.count } do
      Chatroom.between(users(:alice), users(:carol))
    end
  end

  test "a user cannot chat with themselves" do
    assert_not Chatroom.new(first_user: users(:alice), second_user: users(:alice)).valid?
  end

  test "reading the other participant's messages broadcasts a read receipt" do
    chatroom = chatrooms(:alice_bob)

    assert_broadcasts(stream_name_from(chatroom), 1) { chatroom.mark_read_for!(users(:alice)) }
    assert_not_nil chatroom.seen_at_by(users(:alice))
    assert_no_broadcasts(stream_name_from(chatroom)) { chatroom.mark_read_for!(users(:alice)) }
  end

  test "interlocutor and read receipts" do
    chatroom = chatrooms(:alice_bob)
    assert_equal users(:bob), chatroom.interlocutor_of(users(:alice))
    assert_equal 1, chatroom.unread_count_for(users(:alice))

    chatroom.mark_read_for!(users(:alice))
    assert_equal 0, chatroom.unread_count_for(users(:alice))
  end
end
