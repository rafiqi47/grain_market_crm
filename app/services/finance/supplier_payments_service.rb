# app/services/finance/supplier_payments_service.rb
module Finance
  class SupplierPaymentsService
    attr_reader :errors

    def initialize(organization:, user:, supplier:, amount:, payment_method:, reference_number: nil, notes: nil)
      @organization = organization
      @user = user
      @supplier = supplier
      @amount = amount.to_f
      @payment_method = payment_method # e.g., 'bank_transfer', 'cash'
      @reference_number = reference_number
      @notes = notes
      @errors = []
    end

    def call
      return false unless valid_payment?

      ActiveRecord::Base.transaction do
        # Prevent concurrent balance calculation bugs
        @supplier.lock!

        # Subtracting payment reduces the debt amount owed to the company
        new_balance = @supplier.current_balance - @amount

        # Log the immutable payment entry
        ledger_entry = @organization.supplier_ledgers.create!(
          supplier: @supplier,
          entry_type: :payment,
          amount: @amount,
          resulting_balance: new_balance,
          description: "Manual clearing via #{@payment_method.to_s.humanize}. Ref: #{@reference_number || 'None'} | Notes: #{@notes}"
        )

        # Sync the core model state
        @supplier.update!(current_balance: new_balance)

        ledger_entry
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    rescue StandardError => e
      @errors << "Payment transaction failed: #{e.message}"
      false
    end

    private

    def valid_payment?
      if @amount <= 0
        @errors << "Payment amount must be greater than zero."
        return false
      end
      true
    end
  end
end
