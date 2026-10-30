class Comment < ApplicationRecord
  belongs_to :dog
  belongs_to :user

  validates :content, presence: true, length: { maximum: 500 }

  scope :newest_first, -> { order(created_at: :desc) }
end
