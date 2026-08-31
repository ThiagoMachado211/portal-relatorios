class LongTrip < ApplicationRecord
  MIN_VALID_DATE = Date.new(2000, 1, 1)

  validates :traveler_name, presence: true
  validates :travel_date, presence: true
  validates :transport_mode, presence: true

  validates :purchase_value_brl, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :purchase_value_points, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :extra_fees_brl, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :refund_value_brl, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :refund_value_points, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :mileage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :dates_must_be_plausible
  validate :purchase_date_cannot_be_after_travel_date

  def days_between_purchase_and_trip
    return nil unless valid_lead_time_dates?

    (travel_date - purchase_date).to_i
  end

  def final_value_brl
    purchase_value_brl.to_f + extra_fees_brl.to_f - refund_value_brl.to_f
  end

  def final_value_points
    purchase_value_points.to_f - refund_value_points.to_f
  end

  private

  def valid_lead_time_dates?
    purchase_date.present? &&
      travel_date.present? &&
      purchase_date >= MIN_VALID_DATE &&
      travel_date >= MIN_VALID_DATE &&
      purchase_date <= travel_date
  end

  def dates_must_be_plausible
    if purchase_date.present? && purchase_date < MIN_VALID_DATE
      errors.add(:purchase_date, "deve ser igual ou posterior a 01/01/2000")
    end

    if travel_date.present? && travel_date < MIN_VALID_DATE
      errors.add(:travel_date, "deve ser igual ou posterior a 01/01/2000")
    end
  end

  def purchase_date_cannot_be_after_travel_date
    return if purchase_date.blank? || travel_date.blank?
    return if purchase_date <= travel_date

    errors.add(:purchase_date, "não pode ser posterior à data da viagem")
  end
end
