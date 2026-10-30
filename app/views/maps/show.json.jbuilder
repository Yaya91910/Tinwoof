json.type "FeatureCollection"
json.features @dogs do |dog|
  json.type "Feature"
  json.id dog.id
  json.geometry do
    json.type "Point"
    json.coordinates [dog.longitude, dog.latitude]
  end
  json.properties do
    json.id dog.id
    json.name dog.name
    json.breed dog.breed
    json.gender dog.gender
    json.mine dog.owned_by?(current_user)
    json.url dog_path(dog)
    json.photo dog_photo_url(dog, width: 160, height: 160)
  end
end
