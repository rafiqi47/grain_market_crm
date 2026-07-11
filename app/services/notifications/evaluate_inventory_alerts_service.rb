# app/services/notifications/evaluate_inventory_alerts_service.rb
module Notifications
  class EvaluateInventoryAlertsService
    def initialize(organization:)
      @organization = organization
    end

    def call
      alerts_generated = 0

      # Scan all active batches inside this organization
      @organization.product_batches.active.each do |batch|
        next if batch.expiry_date.nil?

        days_remaining = (batch.expiry_date - Date.current).to_i
        
        # Determine target alert type based on urgency
        target_type = nil
        message = ""

        if days_remaining <= 7 && days_remaining >= 0
          target_type = :critical_expiry
          message = "CRITICAL ALERT: Batch #{batch.batch_number} for '#{batch.product.name}' expires in #{days_remaining} days! (#{batch.expiry_date})"
        elsif days_remaining <= 30 && days_remaining > 7
          target_type = :near_expiry
          message = "Warning: Batch #{batch.batch_number} for '#{batch.product.name}' is approaching expiration. #{days_remaining} days remaining."
        end

        # If it fits an alert window, check if an unread alert of this type already exists
        if target_type.present?
          unless @organization.inventory_alerts.unread.exists?(product_batch_id: batch.id, alert_type: target_type)
            @organization.inventory_alerts.create!(
              product_batch: batch,
              alert_type: target_type,
              message: message
            )
            alerts_generated += 1
          end
        end
      end

      alerts_generated
    end
  end
end
