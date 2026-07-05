class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable

  # Define Roles Enum
  enum :role, { manager: 0, owner: 1, super_admin: 2 }, default: :manager
end