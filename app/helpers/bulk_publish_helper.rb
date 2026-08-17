module BulkPublishHelper
  def manifest_time(value)
    Time.iso8601(value.to_s).strftime("%Y-%m-%d %H:%M:%S %Z")
  rescue ArgumentError
    value.presence || "n/a"
  end

  # Turns an ISO 8601 duration such as "PT1M" into "1 minute"
  def manifest_cadence(value)
    return "n/a" if value.blank?

    ActiveSupport::Duration.parse(value).inspect
  rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
    value
  end
end
