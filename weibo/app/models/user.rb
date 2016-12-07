class User < ActiveRecord::Base
  has_many :posts

  validates :userName, presence: true, length: {maximum: 20}
  EMAIL=/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: {maximum: 255}, format: {with: EMAIL},uniqueness: {case_sensitive: false}

  has_secure_password
  validates :password, length: {minimum: 6}
end
