class ReportPage < ApplicationRecord
  belongs_to :sidebar_section
  belongs_to :sidebar_subsection

  validates :sidebar_subsection, presence: true

  has_one_attached :file

  enum :content_type, {
    pdf: 0,
    report: 1,
    heatmap: 2,
    streamlit: 3,
    external_link: 4,
    image: 5
  }

  enum :visible_for, {
    manager: 0,
    client: 1,
    shared: 2
  }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :title) }

  validates :title, presence: true
  validates :slug, presence: true

  def visible_to?(user)
    shared? || visible_for == user.user_type
  end
end