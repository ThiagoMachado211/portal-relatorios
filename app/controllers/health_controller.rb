class HealthController < ApplicationController
  def index
    render html: "<h1>APP OK</h1>".html_safe
  end
end