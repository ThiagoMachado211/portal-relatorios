class SidebarSection < ApplicationRecord
  has_many :report_pages, dependent: :destroy

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :title) }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
end