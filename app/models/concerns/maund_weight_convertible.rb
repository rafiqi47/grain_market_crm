# app/models/concerns/maund_weight_convertible.rb
#
# Include in any model that stores a weight in KG but wants to accept/display
# it as Maund + KG (1 Maund = 40 KG, standard Pakistani mann).
#
# Usage:
#   class CropPurchase < ApplicationRecord
#     include MaundWeightConvertible
#     maund_weight_field :gross_weight
#     maund_weight_field :katt_deduction
#     maund_weight_field :net_weight
#   end
#
# This generates, for each field e.g. :gross_weight:
#   - attr_accessor :gross_weight_maund, :gross_weight_kg_part   (virtual form inputs)
#   - #gross_weight_maund_display / #gross_weight_kg_part_display (for pre-filling edit forms)
#   - #gross_weight_formatted  => "10 Maund 15 KG"
#
# The underlying `gross_weight` column always stores the total in KG. When
# gross_weight_maund / gross_weight_kg_part are present on assignment, they
# are combined into the real column before validation.
module MaundWeightConvertible
  extend ActiveSupport::Concern

  KG_PER_MAUND = 40

  class_methods do
    def maund_weight_field(field)
      attr_accessor :"#{field}_maund", :"#{field}_kg_part"

      before_validation do
        maund = send(:"#{field}_maund")
        kg_part = send(:"#{field}_kg_part")

        next if maund.blank? && kg_part.blank?

        total_kg = maund.to_f * MaundWeightConvertible::KG_PER_MAUND + kg_part.to_f
        send(:"#{field}=", total_kg)
      end

      define_method(:"#{field}_maund_display") do
        value = send(field)
        return nil if value.blank?
        (value / MaundWeightConvertible::KG_PER_MAUND).to_i
      end

      define_method(:"#{field}_kg_part_display") do
        value = send(field)
        return nil if value.blank?
        (value % MaundWeightConvertible::KG_PER_MAUND).round(2)
      end

      define_method(:"#{field}_formatted") do
        value = send(field)
        return "0 Maund 0 KG" if value.blank?
        maund, kg = value.divmod(MaundWeightConvertible::KG_PER_MAUND)
        "#{maund.to_i} Maund #{kg.round(2)} KG"
      end
    end
  end
end
