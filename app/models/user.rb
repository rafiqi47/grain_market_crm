class User < ApplicationRecord
  # Relations
  belongs_to :organization, optional: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable

  # Define Roles Enum
  enum :role, { manager: 0, owner: 1, super_admin: 2 }, default: :manager

  # Validations
  validates :full_name, presence: true
  validates :organization, presence: true, if: -> { owner? || manager? }
  validate :only_one_owner_per_organization, if: :owner?

  private

  def only_one_owner_per_organization
    return unless organization

    if organization.users.where(role: :owner).where.not(id: id).exists?
      errors.add(:organization, "already has an owner")
    end
  end
end
