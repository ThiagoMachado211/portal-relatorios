class ReportPage < ApplicationRecord
  belongs_to :sidebar_section, optional: true

  has_one_attached :internal_file
  has_one_attached :external_file

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
end