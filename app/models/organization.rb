class Organization < ApplicationRecord
  has_one   :owner, -> { where(role: :owner) }, class_name: "User", dependent: :destroy
  has_many  :managers, -> { where(role: :manager) }, class_name: "User", dependent: :destroy
  has_many  :users, dependent: :destroy

  accepts_nested_attributes_for :owner

  validates :name, presence: true
  validate  :single_owner

  private

  def single_owner
    return unless owner && owner.organization_id == id
    if users.where(role: :owner).where.not(id: owner.id).exists?
      errors.add(:base, "Organization can only have one owner")
    end
  end
end
