class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    return unless calendar_visible?

    @calendar_items = CalendarData.mg_items

    @upcoming_events =
      build_upcoming_events(@calendar_items)
        .select { |item| item[:event_date] >= Date.current }
        .sort_by { |item| item[:event_date] }
        .first(8)
  end

  private

  def calendar_visible?
    current_user.admin? || current_user.manager?
  end

  def build_upcoming_events(calendar_items)
    calendar_items.flat_map do |item|
      build_events_for(item)
    end
  end

  def build_events_for(item)
    events = []

    add_event(
      events,
      item,
      :print_file_date,
      "Arquivo para impressão"
    )

    add_event(
      events,
      item,
      :upload_start_date,
      "Início do upload"
    )

    add_event(
      events,
      item,
      :upload_end_date,
      "Fim do upload"
    )

    add_event(
      events,
      item,
      :result_date,
      "Divulgação do resultado"
    )

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