class SidebarSection < ApplicationRecord
  has_many :report_pages, dependent: :nullify

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
end