module Inventory
  class ExpiryScannerService
    def self.call
      new.call
    end

    def call
      # Scan active batches expiring within the next 30 days
      batches_to_flag = ProductBatch.active.expiring_within(30).includes(product: :organization)

      batches_to_flag.find_each do |batch|
        organization = batch.product.organization
        days_remaining = (batch.expiry_date - Date.current).to_i

        # Determine urgency tier
        alert_type = days_remaining <= 7 ? :critical_expiry : :near_expiry
        message = "Batch #{batch.batch_number} of #{batch.product.name} expires in #{days_remaining} days (#{batch.expiry_date})."

        # Safe upsert to avoid duplicate notifications on consecutive daily runs
        InventoryAlert.find_or_create_by!(
          product_batch: batch,
          alert_type: alert_type,
          read_at: nil
        ) do |alert|
          alert.organization = organization
          alert.message = message
        end
      end
    end
  end
end
