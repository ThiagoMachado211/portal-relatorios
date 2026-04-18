class LongTrip < ApplicationRecord
  validates :traveler_name, presence: true
  validates :travel_date, presence: true
  validates :transport_mode, presence: true

  validates :purchase_value_brl, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :purchase_value_points, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :extra_fees_brl, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :refund_value_brl, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :refund_value_points, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :mileage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def days_between_purchase_and_trip
    return nil if purchase_date.blank? || travel_date.blank?

    (travel_date - purchase_date).to_i
  end

  def final_value_brl
    purchase_value_brl.to_f + extra_fees_brl.to_f - refund_value_brl.to_f
  end

  def final_value_points
    purchase_value_points.to_f - refund_value_points.to_f
  end
end