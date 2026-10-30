class PwaController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def manifest
    render formats: :json, content_type: "application/manifest+json"
  end

  def service_worker
    response.headers["Cache-Control"] = "no-cache"
    render formats: :js, content_type: "text/javascript"
  end
end
