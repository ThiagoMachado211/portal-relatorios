class TravelMetric < ApplicationRecord
  belongs_to :user

  CATEGORIES = [
    "Passagens Aéreas",
    "Hospedagem",
    "Translado"
  ].freeze

  METRIC_TYPES = [
    "Quantidade",
    "Valor"
  ].freeze

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :metric_type, presence: true, inclusion: { in: METRIC_TYPES }
  validates :state, presence: true
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
end