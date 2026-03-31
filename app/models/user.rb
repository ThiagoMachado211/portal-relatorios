class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

enum :user_type, {
  client: 0,
  manager: 1,
  admin: 2
}

  validates :name, presence: true
end
