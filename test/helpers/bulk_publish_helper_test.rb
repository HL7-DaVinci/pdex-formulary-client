require "test_helper"

class BulkPublishHelperTest < ActionView::TestCase
  test "manifest_time formats an ISO 8601 timestamp" do
    assert_equal "2026-08-16 08:18:09 UTC", manifest_time("2026-08-16T08:18:09.813767411Z")
  end

  test "manifest_time falls back to the raw value" do
    assert_equal "not-a-time", manifest_time("not-a-time")
    assert_equal "n/a", manifest_time(nil)
  end

  test "manifest_cadence humanizes an ISO 8601 duration" do
    assert_equal "1 minute", manifest_cadence("PT1M")
    assert_equal "1 day", manifest_cadence("P1D")
  end

  test "manifest_cadence falls back to the raw value" do
    assert_equal "n/a", manifest_cadence(nil)
    assert_equal "whenever", manifest_cadence("whenever")
  end
end
