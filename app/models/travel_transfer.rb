class TravelTransfer < ApplicationRecord
  validates :travel_request_id, presence: true
  validates :estimated_mileage, :value_brl,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
