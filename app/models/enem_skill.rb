class EnemSkill < ApplicationRecord
  validates :area, presence: true
  validates :skill_code, presence: true

  validates :skill_code,
            uniqueness: { scope: :area }
end