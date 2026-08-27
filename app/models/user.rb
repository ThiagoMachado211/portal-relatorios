class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :travel_metrics, dependent: :destroy

  enum :user_type, {
    client: 0,
    manager: 1,
    admin: 2
  }

  validates :name, presence: true


  # Gestão de Viagens:
  # manager e admin podem acessar dados financeiros;
  # client acessa somente a visão operacional.
  def can_view_travel_financial_data?
    manager? || admin?
  end

  def can_view_full_travel_presentation?
    can_view_travel_financial_data?
  end
end
