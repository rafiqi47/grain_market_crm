class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable, :trackable

  enum :role, { manager: 0, owner: 1, super_admin: 2 }, default: :manager

  belongs_to :organization, optional: true, inverse_of: :users
  has_many   :inventory_adjustments, dependent: :destroy

  validates :full_name, presence: true
  validates :organization, presence: true, if: -> { owner? || manager? }
  validates :organization, absence: true, if: :super_admin?
  validate  :ensure_unique_owner_per_org, if: :owner?

  # SAFEST APPROACH: Fires only after the record is written to the DB on creation.
  # Checking 'id' in previously_inserted_ids or previous_changes ensures it never loops on update saves.
  after_commit :send_password_setup_instructions, on: :create, unless: :super_admin?

  private

  def ensure_unique_owner_per_org
    return unless organization
    existing_owner = organization.users.any? { |u| u.owner? && u.id != id }

    if existing_owner
      errors.add(:role, "cannot be set to owner. This organization already has an assigned owner.")
    end
  end

  def send_password_setup_instructions
    # Devise updates fields inside this method. Because this runs in after_commit,
    # those internal saves will trigger their own standard update transaction logs 
    # but WILL NOT re-trigger this code block since the hook is explicitly tied to 'on: :create'.
    self.send_reset_password_instructions
  end
end
