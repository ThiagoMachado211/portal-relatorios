class EnemStateResult < ApplicationRecord
  DEPENDENCIES = %w[Federal Estadual Municipal Privada].freeze

  validates :year,
            presence: true,
            inclusion: { in: 2016..2025 }

  validates :state_code, presence: true
  validates :administrative_dependency,
            presence: true,
            inclusion: { in: DEPENDENCIES }

  validates :year,
            uniqueness: {
              scope: [:state_code, :administrative_dependency]
            }

  scope :for_year, ->(year) { where(year: year) if year.present? }
  scope :for_state, ->(state_code) { where(state_code: state_code) if state_code.present? }
  scope :for_dependency, ->(dependency) {
    where(administrative_dependency: dependency) if dependency.present?
  }

  def brazil?
    state_code == "Brasil"
  end
end
