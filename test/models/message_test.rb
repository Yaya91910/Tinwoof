require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  include Turbo::Streams::StreamName

  test "only participants can post" do
    message = chatrooms(:alice_bob).messages.new(user: users(:carol), content: "Coucou")
    assert_not message.valid?
  end

  test "posting broadcasts the message and refreshes the recipient's badge" do
    chatroom = chatrooms(:alice_bob)

    assert_broadcasts(stream_name_from(chatroom), 1) do
      assert_broadcasts(stream_name_from([users(:bob), :inbox]), 1) do
        chatroom.messages.create!(user: users(:alice), content: "Samedi 10 h ?")
      end
    end
    assert_not_nil chatroom.reload.last_message_at
  end
end
