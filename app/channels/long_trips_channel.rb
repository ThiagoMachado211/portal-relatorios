class LongTripsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "long_trips_updates"
  end

  def unsubscribed
  end
end