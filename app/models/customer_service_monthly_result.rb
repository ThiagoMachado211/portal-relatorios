class CustomerServiceMonthlyResult < ApplicationRecord
  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, presence: true,
                    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :source_filename, presence: true
  validates :year, uniqueness: { scope: :month }

  scope :chronological, -> { order(:year, :month) }

  MONTH_NAMES = {
    1 => "Jan", 2 => "Fev", 3 => "Mar", 4 => "Abr",
    5 => "Mai", 6 => "Jun", 7 => "Jul", 8 => "Ago",
    9 => "Set", 10 => "Out", 11 => "Nov", 12 => "Dez"
  }.freeze

  def month_label
    "#{MONTH_NAMES.fetch(month)}/#{year.to_s.last(2)}"
  end
end
