class SidebarSubsection < ApplicationRecord
  belongs_to :sidebar_section
  has_many :report_pages, dependent: :nullify

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :title) }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :sidebar_section_id }
end