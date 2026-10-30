require "test_helper"

class ChatTest < ActionDispatch::IntegrationTest
  test "inbox lists conversations with unread counts" do
    sign_in users(:alice)
    get chatrooms_path
    assert_select ".inbox__name", "Bob"
    assert_select ".inbox__item.is-unread .badge", "1"
  end

  test "opening a conversation marks it as read" do
    sign_in users(:alice)
    get chatroom_path(chatrooms(:alice_bob))
    assert_response :success
    assert_equal 0, users(:alice).unread_messages_count
  end

  test "outsiders cannot read or post in a conversation" do
    sign_in users(:carol)
    get chatroom_path(chatrooms(:alice_bob))
    assert_response :not_found

    sign_in users(:carol)
    post chatroom_messages_path(chatrooms(:alice_bob)), params: { message: { content: "Intrus" } }
    assert_response :not_found
  end

  test "participants post messages" do
    sign_in users(:alice)
    assert_difference -> { chatrooms(:alice_bob).messages.count } do
      post chatroom_messages_path(chatrooms(:alice_bob)), params: { message: { content: "Samedi 10 h ?" } }, as: :turbo_stream
    end
    assert_response :success
  end

  test "starting a conversation from a profile" do
    sign_in users(:carol)
    assert_difference -> { Chatroom.count } do
      post chatrooms_path(user_id: users(:bob).id)
    end
    assert_redirected_to chatroom_path(Chatroom.last)
  end
end
