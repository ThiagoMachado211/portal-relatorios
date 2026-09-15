class EnemSkillResult < ApplicationRecord
  validates :year,
            :uf,
            :dependency,
            :area,
            :skill_code,
            presence: true

  validates :skill_code,
            uniqueness: {
              scope: [
                :year,
                :uf,
                :dependency,
                :area
              ]
            }
end