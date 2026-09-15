class EnemSkillDistribution < ApplicationRecord
  validates :year, :area, :skill_code, presence: true

  validates :skill_code,
            uniqueness: {
              scope: [:year, :area]
            }
end