class InventoryExpiryScanJob < ApplicationJob
  queue_as :default

  def perform
    Inventory::ExpiryScannerService.call
  end
end
