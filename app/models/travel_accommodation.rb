class TravelAccommodation < ApplicationRecord
  validates :travel_request_id, presence: true
  validates :stay_duration_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :average_daily_rate_brl, :total_stay_value_brl,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
