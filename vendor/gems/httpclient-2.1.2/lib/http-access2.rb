# HTTPAccess2 - HTTP accessing library.
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi  <nakahiro@sarion.co.jp>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.

# http-access2.rb is based on http-access.rb in http-access/0.0.4.  Some part
# of code in http-access.rb was recycled in http-access2.rb.  Those part is
# copyrighted by Maehashi-san.


require 'httpclient'


module HTTPAccess2
  VERSION = ::HTTPClient::VERSION
  RUBY_VERSION_STRING = ::HTTPClient::RUBY_VERSION_STRING
  RCS_FILE, RCS_REVISION = ::HTTPClient::RCS_FILE, ::HTTPClient::RCS_REVISION
  SSLEnabled = ::HTTPClient::SSLEnabled
  SSPIEnabled = ::HTTPClient::SSPIEnabled
  DEBUG_SSL = ::HTTPClient::DEBUG_SSL

  Util = ::HTTPClient::Util

  class Client < ::HTTPClient
    class RetryableResponse < StandardError
    end
  end

  SSLConfig = ::HTTPClient::SSLConfig
  BasicAuth = ::HTTPClient::BasicAuth
  DigestAuth = ::HTTPClient::DigestAuth
  NegotiateAuth = ::HTTPClient::NegotiateAuth
  AuthFilterBase = ::HTTPClient::AuthFilterBase
  WWWAuth = ::HTTPClient::WWWAuth
  ProxyAuth = ::HTTPClient::ProxyAuth
  Site = ::HTTPClient::Site
  Connection = ::HTTPClient::Connection
  SessionManager = ::HTTPClient::SessionManager
  SSLSocketWrap = ::HTTPClient::SSLSocketWrap
  DebugSocket = ::HTTPClient::DebugSocket

  class Session < ::HTTPClient::Session
    class Error < StandardError
    end
    class InvalidState < Error
    end
    class BadResponse < Error
    end
    class KeepAliveDisconnected < Error
    end
  end
end