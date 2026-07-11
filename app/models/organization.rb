class Organization < ApplicationRecord
  has_one   :owner, -> { where(role: :owner) }, class_name: "User", dependent: :destroy, inverse_of: :organization
  has_many  :managers, -> { where(role: :manager) }, class_name: "User", dependent: :destroy, inverse_of: :organization
  has_many  :users, dependent: :destroy, inverse_of: :organization
  has_many  :suppliers, dependent: :destroy, inverse_of: :organization
  has_many  :products, dependent: :destroy, inverse_of: :organization
  has_many  :inventory_alerts, dependent: :destroy

  # Allow nested management for onboarding forms
  accepts_nested_attributes_for :owner, reject_if: :all_blank

  # Validations
  validates :name, presence: true, uniqueness: true
  validate  :single_owner_constraint

  private

  def single_owner_constraint
    # Look through the in-memory array using 'target' instead of querying the DB
    # This detects multiple owners added via nested attributes or association builders
    all_owners = users.select { |u| u.owner? && !u.marked_for_destruction? }

    if all_owners.size > 1
      errors.add(:base, "Organization can only have one primary owner")
    end
  end
end
