require "test_helper"

class DogTest < ActiveSupport::TestCase
  test "requires a name, a breed and a known gender" do
    dog = Dog.new(user: users(:alice), gender: "robot")
    assert_not dog.valid?
    assert_includes dog.errors.attribute_names, :name
    assert_includes dog.errors.attribute_names, :breed
    assert_includes dog.errors.attribute_names, :gender
  end

  test "normalizes traits and rejects unknown ones" do
    dog = dogs(:luna)
    dog.traits = ["calm", "", "calm", "sporty"]
    assert dog.valid?
    assert_equal %w[calm sporty], dog.traits

    dog.traits = ["grumpy"]
    assert_not dog.valid?
  end

  test "caps the number of traits" do
    dog = dogs(:luna)
    dog.traits = Dog::TRAITS.first(Dog::MAX_TRAITS + 1)
    assert_not dog.valid?
  end

  test "geocodes a new address server-side" do
    dog = dogs(:luna)
    dog.update!(address: "Somewhere in Paris", latitude: nil, longitude: nil)
    assert_equal [48.8566, 2.3522], [dog.latitude, dog.longitude]
  end

  test "keeps coordinates picked by the autocomplete" do
    dog = dogs(:luna)
    dog.update!(address: "Parc Monceau", latitude: 48.8797, longitude: 2.3091)
    assert_equal [48.8797, 2.3091], [dog.latitude, dog.longitude]
  end

  test "around lists dogs within the radius, closest first" do
    dogs = Dog.around(users(:alice)).not_owned_by(users(:alice)).to_a

    assert_equal [dogs(:rex), dogs(:luna)], dogs
    assert dogs.first.distance < dogs.last.distance
  end

  test "around falls back to all geocoded dogs without a position" do
    assert_includes Dog.around(users(:bob)).to_a, dogs(:ollie)
  end

  test "unswiped_by hides dogs already liked or passed" do
    Swipe.create!(user: users(:alice), dog: dogs(:rex), liked: false)
    assert_not_includes Dog.unswiped_by(users(:alice)), dogs(:rex)
  end
end
