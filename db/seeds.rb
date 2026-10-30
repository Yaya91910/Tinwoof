# Demo data: a Parisian dog community, a demo account and a few pending likes,
# so that the demo account's first swipes immediately turn into matches.
#
#   bin/rails db:seed
#   → log in with demo@tinwoof.app / tinwoof123
abort "Refusing to seed production (set ALLOW_SEEDS=1 to force)." if Rails.env.production? && ENV["ALLOW_SEEDS"].blank?

require "open-uri"

PASSWORD = "tinwoof123".freeze

def photo(id)
  "https://images.unsplash.com/#{id}?auto=format&fit=crop&w=900&q=75"
end

def attach_remote(attachment, url, filename)
  attachment.attach(io: URI.parse(url).open(open_timeout: 5, read_timeout: 15), filename: filename, content_type: "image/jpeg")
rescue StandardError => e
  puts "  ⚠ #{filename} skipped (#{e.class})"
end

puts "Cleaning database…"
Chatroom.destroy_all
User.destroy_all

puts "Creating demo account…"
demo = User.create!(
  email: "demo@tinwoof.app", password: PASSWORD, first_name: "Yassin", last_name: "Démo", admin: true,
  bio: "Toujours partant pour une balade au bord du canal 🐾",
  latitude: 48.859, longitude: 2.379, address: "Paris 11e", located_at: Time.current, last_seen_at: Time.current
)
attach_remote(demo.photo, "https://i.pravatar.cc/300?img=12", "demo.jpg")

pixel = demo.dogs.create!(
  name: "Pixel", gender: "male", age: 4, breed: "Jack Russell", height_cm: 30, traits: %w[playful sporty curious],
  description: "Une pile électrique qui adore les balles et les copains de toutes tailles.",
  address: "Square Maurice Gardette, Paris 11e", latitude: 48.8636, longitude: 2.3746
)
attach_remote(pixel.photos, photo("photo-1507146426996-ef05306b995a"), "pixel.jpg")

COMMUNITY = [
  { first_name: "Karim", last_name: "Meghraoui", avatar: 33, dog: { name: "Chowy", gender: "female", age: 10, breed: "Chow-Chow", height_cm: 50, traits: %w[calm cuddly], address: "Champ de Mars, Paris 7e", latitude: 48.8556, longitude: 2.2986, description: "Très calme 🌛, elle adore faire la sieste au soleil. Écrivez-moi pour une balade tranquille.", photo: "photo-1591300673309-092e8afa699b" } },
  { first_name: "Olympia", last_name: "Beaulac", avatar: 47, dog: { name: "Bull", gender: "male", age: 8, breed: "Bouledogue anglais", height_cm: 40, traits: %w[playful sociable], address: "Canal Saint-Martin, Paris 10e", latitude: 48.8722, longitude: 2.3606, description: "Joueur et gourmand, il adore les balades du soir le long du canal.", photo: "photo-1554254278-4e0a32570ec9" } },
  { first_name: "Merouane", last_name: "Masaoudi", avatar: 59, dog: { name: "Hachikō", gender: "male", age: 10, breed: "Akita Inu", height_cm: 64, traits: %w[protective calm], address: "Parc des Buttes-Chaumont, Paris 19e", latitude: 48.8809, longitude: 2.3828, description: "Le plus fidèle des chiens ♥️ Venez faire connaissance !", photo: "photo-1618911392268-9fc29c67fc69" } },
  { first_name: "Hidesaburō", last_name: "Ueno", avatar: 60, dog: { name: "Croky", gender: "female", age: 7, breed: "Golden Retriever", height_cm: 61, traits: %w[sociable playful cuddly], address: "Parc de Bercy, Paris 12e", latitude: 48.8355, longitude: 2.3843, description: "Il y a des bâtons partout chez moi, désolée pour le bazar… 😭", photo: "photo-1561572903-ab17e3916acd" } },
  { first_name: "Alexandre", last_name: "Pépé", avatar: 15, dog: { name: "Loki", gender: "male", age: 13, breed: "Chihuahua", height_cm: 16, traits: %w[curious protective], address: "Place des Vosges, Paris 4e", latitude: 48.8556, longitude: 2.3655, description: "N'a peur d'aucun grand chien et aboie pour avoir le dernier mot ‼️", photo: "photo-1563172320-c91f912fb5b8" } },
  { first_name: "Édouard", last_name: "Moreau", avatar: 52, dog: { name: "Zeus", gender: "male", age: 6, breed: "Dogue allemand", height_cm: 86, traits: %w[cuddly calm], address: "Jardin du Luxembourg, Paris 6e", latitude: 48.8462, longitude: 2.3372, description: "Un géant pot de colle, plein d'amour à partager ♥️", photo: "photo-1533764625214-b97671494f23" } },
  { first_name: "Fifine", last_name: "Thériault", avatar: 44, dog: { name: "Canou", gender: "male", age: 5, breed: "Caniche", height_cm: 24, traits: %w[shy playful], address: "Parc Monceau, Paris 8e", latitude: 48.8797, longitude: 2.3091, description: "Timide au début, puis complètement fou 💫", photo: "photo-1622923169587-d2ebef5cf300" } },
  { first_name: "Joséphine", last_name: "Saindon", avatar: 45, dog: { name: "Bucky", gender: "female", age: 7, breed: "Husky", height_cm: 55, traits: %w[sporty sociable], address: "Bois de Vincennes, Paris 12e", latitude: 48.8285, longitude: 2.4330, description: "Adore courir : préparez vos baskets pour un footing intensif 🤭", photo: "photo-1590419690008-905895e8fe0d" } },
  { first_name: "Guillaume", last_name: "D'Aoust", avatar: 53, dog: { name: "Vidar", gender: "female", age: 9, breed: "Staffordshire Bull Terrier", height_cm: 35, traits: %w[playful protective], address: "Square du Temple, Paris 3e", latitude: 48.8645, longitude: 2.3605, description: "Préfère les grands chiens mais reste ouverte à toutes les rencontres 😳", photo: "photo-1648979650858-753770ba9405" } },
  { first_name: "Catherine", last_name: "Blais", avatar: 32, dog: { name: "Dookie", gender: "male", age: 5, breed: "Welsh Corgi", height_cm: 25, traits: %w[sociable curious], address: "Coulée verte René-Dumont, Paris 12e", latitude: 48.8465, longitude: 2.3800, description: "Super sociable, toujours partant pour une nouvelle rencontre 🥰", photo: "photo-1634635880938-d81e973bcd6c" } },
  { first_name: "Julie", last_name: "Desnoyers", avatar: 20, dog: { name: "Puly", gender: "male", age: 10, breed: "Berger australien", height_cm: 52, traits: %w[sporty curious], address: "Parc de Belleville, Paris 20e", latitude: 48.8714, longitude: 2.3847, description: "Toujours dans la lune, mais tellement de qualités 😇", photo: "photo-1587300003388-59208cc962cb" } },
  { first_name: "Sennet", last_name: "Marleau", avatar: 25, dog: { name: "Simba", gender: "female", age: 3, breed: "Caniche royal abricot", height_cm: 58, traits: %w[playful sporty sociable], address: "Jardin des Plantes, Paris 5e", latitude: 48.8440, longitude: 2.3590, description: "Toujours à 100 % de son énergie 🥵 Jamais fatiguée… contrairement à moi 😤", photo: "photo-1548199973-03cce0bbc87b" } },
  { first_name: "Somerville", last_name: "Gousse", avatar: 68, dog: { name: "Dumble", gender: "male", age: 13, breed: "Griffon bruxellois", height_cm: 28, traits: %w[calm curious], address: "Square Gardette, Paris 11e", latitude: 48.8640, longitude: 2.3760, description: "A voyagé partout dans le monde, très ouvert aux nouvelles rencontres 👍🏼", photo: "photo-1517849845537-4d257902454a" } },
  { first_name: "Eloïse", last_name: "Martel", avatar: 9, dog: { name: "Anna", gender: "female", age: 4, breed: "Samoyède", height_cm: 53, traits: %w[cuddly sociable], address: "Trocadéro, Paris 16e", latitude: 48.8616, longitude: 2.2893, description: "Fan de La Reine des neiges ❄️ — pour le prénom, c'est une coïncidence. Un amour ⛄️", photo: "photo-1596492784531-6e6eb5ea9993" } },
  { first_name: "Dexter", last_name: "Mailly", avatar: 11, dog: { name: "Tibo", gender: "female", age: 2, breed: "Shiba Inu", height_cm: 38, traits: %w[curious shy], address: "Île Saint-Louis, Paris 4e", latitude: 48.8516, longitude: 2.3570, description: "Un sourire sur commande ? Demandez-lui, elle vous offrira ses plus beaux woofs 🥰", photo: "photo-1636291494567-2cde2d6f45d4" } },
  { first_name: "Inès", last_name: "Roux", avatar: 41, dog: { name: "Ollie", gender: "male", age: 1, breed: "Beagle", height_cm: 36, traits: %w[playful curious sociable], address: "Parc de la Tête d'Or, Lyon", latitude: 45.7772, longitude: 4.8550, description: "Le nez toujours collé au sol, il suit toutes les pistes… surtout celles des goûters.", photo: "photo-1543466835-00a7907e9de1" } },
  { first_name: "Malik", last_name: "Benali", avatar: 14, dog: { name: "Nala", gender: "female", age: 3, breed: "Bouledogue français", height_cm: 30, traits: %w[cuddly playful], address: "Vieux-Port, Marseille", latitude: 43.2951, longitude: 5.3740, description: "Ronfle comme un tracteur, câline comme personne.", photo: "photo-1583511655857-d19b40a7a54e" } }
].freeze

puts "Creating #{COMMUNITY.size} owners and their dogs…"
owners = COMMUNITY.map.with_index do |entry, index|
  owner = User.create!(
    email: "#{I18n.transliterate(entry[:first_name]).downcase}@tinwoof.app", password: PASSWORD,
    first_name: entry[:first_name], last_name: entry[:last_name],
    last_seen_at: index.even? ? Time.current : 2.days.ago
  )
  attach_remote(owner.photo, "https://i.pravatar.cc/300?img=#{entry[:avatar]}", "#{owner.first_name}.jpg")

  attributes = entry[:dog].except(:photo)
  dog = owner.dogs.create!(attributes)
  attach_remote(dog.photos, photo(entry[:dog][:photo]), "#{dog.name.parameterize}.jpg")
  print "."
  owner
end
puts

puts "Liking Pixel so that the demo account's first likes become matches…"
owners.first(6).each_with_index do |owner, index|
  Swipe.create!(user: owner, dog: pixel, liked: true, superlike: index < 2)
end

puts "Starting a conversation…"
olympia = owners.find { |owner| owner.first_name == "Olympia" }
Swipe.create!(user: demo, dog: olympia.dogs.first, liked: true)
chatroom = Chatroom.between(demo, olympia)
[
  [olympia, "Coucou ! Bull a adoré le profil de Pixel 😄"],
  [demo, "Haha Pixel aussi ! Canal Saint-Martin samedi matin ?"],
  [olympia, "Parfait, 10 h au niveau de l'écluse des Récollets ?"]
].each_with_index do |(author, content), index|
  chatroom.messages.create!(user: author, content: content, created_at: (30 - index * 10).minutes.ago,
                            read_at: (Time.current unless index == 2))
end

puts "Leaving a few mots doux…"
["Trop mignon 😍", "On se croise au square ?", "Quelle bouille !", "Un vrai champion de la balle 🎾", "Toujours partant pour un tour du canal !"]
  .zip(owners.sample(5, random: Random.new(42)))
  .each { |content, owner| pixel.comments.create!(user: owner, content: content) }

puts "\nDone! Log in with demo@tinwoof.app / #{PASSWORD}"
