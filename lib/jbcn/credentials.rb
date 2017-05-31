# frozen_string_literal: true

module Jbcn
  class Credentials
    attr_reader :token

    def authenticate(_faraday)
      fail(NotImplementedError)
    end
  end

  class CodeCredentials < Credentials
    AUTH_ENDPOINT = "https://ssl.jobcan.jp/m/work/accessrecord?_m=adit&code="

    attr_reader :code

    def initialize(code)
      @code = code
    end

    def authenticate(faraday)
      response = faraday.get(AUTH_ENDPOINT + @code) rescue
        fail(AuthError.new(credentials: self))

      unless response.status == 200
        fail(AuthError.new(credentials: self, response: response))
      end

      @token = response.body[/<input type="hidden" class="token" name="token" value="([^"]+)">/, 1] or
        fail(AuthTokenNotFoundError.new(credentials: self, response: response))

      @token
    end
  end

  class UserCredentials < Credentials
    AUTH_ENDPOINT = "https://ssl.jobcan.jp/login/pc-employee/try"

    attr_reader :client_id, :username, :password

    def initialize(client_id:, username:, password:)
      @client_id = client_id
      @username = username
      @password = password
    end

    def authenticate(faraday)
      response = faraday.post(AUTH_ENDPOINT, params) rescue
        fail(AuthError.new(credentials: self))

      unless response.status == 200
        fail(AuthError.new(response: response))
      end

      @token = response.body[/<input type="hidden" class="token" name="token" value="([^"]+)">/, 1] or
        fail(AuthTokenNotFoundError.new(response: response))

      @token
    end

    private

    def params
      {
        client_id: @client_id,
        email: @username, # email or staff code in fact
        password: @password,
        url: "/employee",
        login_type: "1",
      }
    end
  end
end
