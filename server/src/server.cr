require "kemal"
require "json"
require "./server/*"

CONFIG            = Config.from_json({{ read_file("./.env.json") }})
SUPPORTERS        = [] of String
GITHUB_SUPPORTERS = Tuba::GitHubSupporters.new
DATABASE          = Tuba::Database.new
UPTIMER           = Time.utc
TUBA_ASCII        = ",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,\n  ckkkkkOOO0KKKXXXXXXXXXXKKK00\n     xxkkOO00KKXXXNNNNXXXK0c\n      'xxkOO0KKXXXNNNXXK0x\n        xxkOO0KXXXNNXKK0;\n         xxkO0KXXXNXKK0;\n         .xkO0KKXXXXK0d\n          dxOO0KXXXK0O  .,:loooooooolc;.\n          .xkO0KXXK0Od,dKXNNXXXNNXXNNNXK0l\n           xkO0KXXK0OO0XXKXNX00XNK0KNX0XXK0'\n c;.  .,   xkO0KXXK0O0XXKOdOxkxxOdOdkkxKXXK0\n.xxKxd0XkOO0000000000KXX0OkkdkkkxdOkkxd0KXX0.\n.kON. lO .,00000000000XX0OKKkkOX0kO0XXKKKXX0.\n           xkO0KXXK0O0XXOkKKkxkX0kx0K0KXKKX0.\n           xkO0KXXK0O0XX0kK0kxOK0kk0KO0XXKX0.\n           xkO0KXXK0OOKXXXKKKKKKKKKKKXXXKXX0.\n           xkO0KXXK0O0XKK0KK000K0000K0OKKXX0.\n           okO0KXXK00OXXXKXKO0KX0O0KX00KKXK0\n            xkO0KXXKK0O0KKKKKKKKKKKKKK0KXXKc\n             lkO0KXXXKK00OOOOOOOOOOO00KXXK:\n               lO0KKXXXXXXKKKKKKKKKXXXXKo\n                  .000KKKKKXKKKKKKKKK:"

module Tuba::Server
  struct AnalyticsPostBody
    include JSON::Serializable

    property accounts : Array(String)

    @[JSON::Field(converter: String::RawConverter)]
    property analytics : String
  end

  VERSION = {{read_file("#{__DIR__}/../shard.yml").split("version: ")[1].split("\n")[0]}}

  get "/v1/version" do |env|
    env.response.content_type = "text/plain"
    VERSION
  end

  get "/v1/ping" do |env|
    env.response.content_type = "text/plain"
    res = "pong"
    if env.params.query["token"]? == CONFIG.token
      running_for_span = Time.utc - UPTIMER
      res = <<-TEXT
      #{res}
      Running for: #{running_for_span.days} Days, #{running_for_span.hours} Hours, #{running_for_span.minutes} Minutes, #{running_for_span.seconds} Seconds
      Database size: #{File.exists?(CONFIG.database) ? "#{File.size(CONFIG.database) / (1024 * 1024)}MB" : "0MB"}
      TEXT
    end

    res
  end

  get "/v1/supporters" do |env|
    env.response.content_type = "application/json"
    SUPPORTERS.to_json
  end

  get "/v1/supporters/refresh" do |env|
    if env.params.query["token"]? == CONFIG.token
      update_supporters
    else
      env.response.status_code = 401
    end
  end

  get "/v1/database" do |env|
    if env.params.query["token"]? == CONFIG.token
      if File.exists?(CONFIG.database)
        send_file env, CONFIG.database
      else
        env.response.status_code = 404
      end
    else
      env.response.status_code = 401
    end
  end

  get "/v1/database/clear" do |env|
    if env.params.query["token"]? == CONFIG.token
      DATABASE.clear
    else
      env.response.status_code = 401
    end
  end

  post "/v1/analytics" do |env|
    body = env.request.body
    ua = env.request.headers["User-Agent"]?
    if body.nil? || body == "" || ua.nil? || !ua.downcase.includes?("tuba")
      env.response.status_code = 422
    else
      begin
        json = AnalyticsPostBody.from_json(body)
        analytics_size = json.analytics.size
        next unless json.accounts.size > 0 && analytics_size > 10 && analytics_size < 5000
        DATABASE.insert(json.accounts, json.analytics)
      rescue
        env.response.status_code = 422
      end
    end
  end

  error 401 do |env|
    env.response.content_type = "text/plain"
    TUBA_ASCII
  end

  error 422 do |env|
    env.response.content_type = "text/plain"
    TUBA_ASCII
  end

  error 404 do |env|
    env.response.content_type = "text/plain"
    TUBA_ASCII
  end

  error 403 do |env|
    env.response.content_type = "text/plain"
    TUBA_ASCII
  end

  def self.update_supporters
    SUPPORTERS.clear
    SUPPORTERS.concat(GITHUB_SUPPORTERS.gather)
    SUPPORTERS.to_json
  end
end

Kemal.config.env = "production"
Kemal.run do
  Tuba::Server.update_supporters
end
