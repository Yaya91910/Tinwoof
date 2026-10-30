class PwaController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def manifest
    render formats: :json, content_type: "application/manifest+json"
  end

  def service_worker
    response.headers["Cache-Control"] = "no-cache"
    template = Rails.configuration.x.service_worker ? "pwa/service_worker" : "pwa/service_worker_disabled"
    render template, formats: :js, content_type: "text/javascript"
  end
end
