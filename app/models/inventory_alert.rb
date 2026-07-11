class InventoryAlert < ApplicationRecord
  belongs_to :organization
  belongs_to :product_batch

  enum :alert_type, { near_expiry: 0, critical_expiry: 1 }, default: :near_expiry

  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :latest, -> { order(created_at: :desc) }

  def mark_as_read!
    update!(read_at: Time.current)
  end
end