class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    return unless calendar_visible?

    @calendar_items = CalendarData.mg_items
    @all_events = build_upcoming_events(@calendar_items).sort_by { |item| item[:event_date] }

    @upcoming_events =
      @all_events
        .select { |item| item[:event_date] >= Date.current }
        .first(8)

    @calendar_month = resolve_calendar_month
    @calendar_events = @all_events.group_by { |item| item[:event_date] }

    future_events = @all_events.select { |item| item[:event_date] >= Date.current }

    @dashboard_stats = {
      next_event: future_events.first,
      future_events_count: future_events.size,
      next_30_days_count: future_events.count { |item| item[:event_date] <= Date.current + 30.days },
      test_types_count: @calendar_items.map { |item| item[:test_type] }.compact.uniq.size
    }
  end

  private

  def calendar_visible?
    current_user.admin? || current_user.manager?
  end

  def resolve_calendar_month
    if params[:month].present?
      Date.strptime("#{params[:month]}-01", "%Y-%m-%d").beginning_of_month
    elsif @upcoming_events.present?
      @upcoming_events.first[:event_date].beginning_of_month
    else
      Date.current.beginning_of_month
    end
  rescue ArgumentError
    Date.current.beginning_of_month
  end

  def build_upcoming_events(calendar_items)
    calendar_items.flat_map do |item|
      build_events_for(item)
    end
  end

  def build_events_for(item)
    events = []

    add_event(events, item, :print_file_date, "Arquivo para impressão")
    add_event(events, item, :upload_start_date, "Início do upload")
    add_event(events, item, :upload_end_date, "Fim do upload")
    add_event(events, item, :result_date, "Divulgação do resultado")

    events
  end

  def add_event(events, item, date_key, label)
    date = item[date_key]
    return if date.blank?

    events << {
      test_name: item[:test_name],
      test_type: item[:test_type],
      event_label: label,
      event_date: date
    }
  end
end
