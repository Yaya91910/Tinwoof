require "test_helper"

class DogsTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "nearby list filters by gender and radius" do
    get dogs_path(gender: "female", radius: 25)
    assert_response :success
    assert_select ".dog-card__name", text: /Luna/
    assert_select ".dog-card__name", text: /Rex/, count: 0

    get dogs_path(radius: 2)
    assert_select ".dog-card__name", text: /Luna/, count: 0
  end

  test "a dog profile shows its distance and mots doux" do
    get dog_path(dogs(:rex))
    assert_response :success
    assert_select ".profile-head__meta", /à \d{3} m/
    assert_select ".comment__text", "Trop mignon !"
  end

  test "creating a dog" do
    assert_difference -> { users(:alice).dogs.count } do
      post dogs_path, params: { dog: {
        name: "Moka", gender: "female", breed: "Berger australien", age: 3,
        traits: ["playful", ""], address: "Parc Monceau", latitude: 48.8797, longitude: 2.3091
      } }
    end
    dog = users(:alice).dogs.order(:created_at).last
    assert_redirected_to dog_path(dog)
    assert_equal ["playful"], dog.traits
    assert_equal 48.8797, dog.latitude
  end

  test "invalid dogs re-render the form" do
    post dogs_path, params: { dog: { name: "" } }
    assert_response :unprocessable_entity
    assert_select ".field__error"
  end

  test "only the owner can edit, update or delete a dog" do
    get edit_dog_path(dogs(:rex))
    assert_response :not_found

    # A 404 response does not persist the test session: sign in again.
    sign_in users(:alice)
    patch dog_path(dogs(:rex)), params: { dog: { name: "Hacked" } }
    assert_response :not_found
    assert_equal "Rex", dogs(:rex).reload.name

    sign_in users(:alice)
    delete dog_path(dogs(:rex))
    assert_response :not_found
  end

  test "owners can update and delete their dog" do
    patch dog_path(dogs(:milo)), params: { dog: { name: "Milou", photos: [""] } }
    assert_redirected_to dog_path(dogs(:milo))
    assert_equal "Milou", dogs(:milo).reload.name

    assert_difference -> { Dog.count }, -1 do
      delete dog_path(dogs(:milo))
    end
    assert_redirected_to profile_path
  end

  test "posting a mot doux with Turbo Streams" do
    assert_difference -> { dogs(:rex).comments.count } do
      post dog_comments_path(dogs(:rex)), params: { comment: { content: "Bravo Rex" } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes response.body, "Bravo Rex"
  end
end
