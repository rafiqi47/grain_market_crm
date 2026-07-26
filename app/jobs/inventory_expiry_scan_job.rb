class InventoryExpiryScanJob < ApplicationJob
  queue_as :default

  def perform
    # Iterate through all organizations to ensure every tenant gets scanned
    Organization.find_each do |org|
      Notifications::EvaluateInventoryAlertsService.new(organization: org).call
    end
  end
end
