class TravelSummary < ApplicationRecord
  validates :travel_request_id, presence: true, uniqueness: true
  validates :duration_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :long_segments_value_brl, :short_segments_value_brl, :accommodation_value_brl,
            :total_value_brl, :total_value_points,
            numericality: { greater_than_or_equal_to: 0 }
end
