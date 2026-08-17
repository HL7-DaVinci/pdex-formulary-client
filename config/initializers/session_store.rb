# Session data (compressed plan hashes) exceeds the 4KB cookie limit,
# so sessions live in the Rails cache instead of the cookie jar.
Rails.application.config.session_store ActionDispatch::Session::CacheStore, expire_after: 1.hour
