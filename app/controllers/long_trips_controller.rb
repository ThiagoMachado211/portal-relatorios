class LongTripsController < ApplicationController
  def dashboard
    @page = params[:page].presence || "overview"
    @dashboard_title = "Gestão de Viagens"
    @monthly_series = []

    case @page
    when "overview"
      @dashboard_title = "Visão Geral"

    when "air_quantity"
      @dashboard_title = "Passagens Aéreas: Quantidade"

    when "land_quantity"
      @dashboard_title = "Passagens Terrestres: Quantidade"

    when "air_mileage"
      @dashboard_title = "Passagens Aéreas: Quilometragem"

    when "land_mileage"
      @dashboard_title = "Passagens Terrestres: Quilometragem"

    when "lead_time"
      @dashboard_title = "Passagens Aéreas: Antecedência de Compra"

    when "sector_distribution"
      @dashboard_title = "Distribuição por Setor"

    when "sector_distribution_monthly"
      @dashboard_title = "Distribuição por Setor: Evolução Mensal"

    when "destination_cities"
      @dashboard_title = "Cidades de Destino"

    when "destination_cities_monthly"
      @dashboard_title = "Cidades de Destino: Evolução Mensal"

    else
      @page = "overview"
      @dashboard_title = "Visão Geral"
    end
  end
end