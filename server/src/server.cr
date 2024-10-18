require "kemal"
require "json"
require "./server/*"

CONFIG            = Config.from_json({{ read_file("./.env.json") }})
SUPPORTERS        = [] of String
GITHUB_SUPPORTERS = Tuba::GitHubSupporters.new
DATABASE          = Tuba::Database.new
UPTIMER           = Time.utc
TUBA_ASCII        = "'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''\n.OOOOOOOOOOOOOOOOOOOO00000KKKKXXXXXNNXXXXXXXKKKKKKKK0000000OOOOOOO\n  'xxxxkkkkkkkkkkOOOO0000KKKKKXXXXXXXXXNNNXXXXXXXXXKKKKKKK0000.\n      xxxxxxxkkkkkOOOO000KKKKKXXXXXXXNNNNNNNNNNXXXXKKKKK00x\n        ;xxxxxkkkkkOOO0000KKKKXXXXXXNNNNNNNNNXXXXKKKK000,\n          :xxxxxkkkkOOO000KKKKXXXXXXNNNNNNNXXXXKKKK000,\n            dxxxxkkkOOOO000KKKXXXXXNNNNNNNXXXXKKK000o\n             ,xxxxkkkOOO000KKKXXXXXNNNNNNXXXKKK000O.\n              .xxxxkkkOOO00KKKXXXXXNNNNNXXXKKK00OO\n                xxxxkkkOO000KKKXXXXNNNNXXXKKK00Od\n                 xxxxkkkOO00KKKXXXXXNNXXXKK00OOd\n                  xxxxkkOO00KKKXXXXXNXXXKK00OOk\n                  .xxxxkOO000KKXXXXXXXXKK00OOO\n                   cxxxkkOO00KKXXXXXXXXKK00OO;\n                    dxxkkOO00KKKXXXXXXKK00OOx      ..,;:cccccccccccccccc:;;'.\n                    :xxkkOO00KKKXXXXXKK00OOk'   'lk000KKKKKKKKKKKKKKKKKKKK0000kl'\n                    .dxkkOO00KKKXXXXXKK0OOkk  :O00KKXNNNXXXXXXNNNNXXXXXNNNNXXKK00Ol.\n                     dxxkkOO00KKXXXXKK00OOkl:O0KKKXNWWNNNXXXXWWNNNNXXXWWNNNNXXXKKK00o\n                     lxxkkOO00KKXXXXKK00OkkO00KKXXXKWWNNNXKOOWWNNNNXOOXWNNNNX0XXXXKK0O.\n                     ;xxkkOO00KKXXXXKK0OOkO0KKXXXXKkkKXXXOkXKxKXXX0xKXkOXXXKkkKXXXXKK0O.\n .,;,                ,xxkkOO00KKXXXXKK0OOO00KXXXXKKOdxO0OdxK0ddk00xd0KxdxOKkdk0KXXXXKK0O\n ooool'.     kOl     ,xxkkOO00KKXXXXKK0OOO0KKXXXK0KdddkOxddkxddxOkddxkddxOOddxK0KXXXXK00,\n odddx00O;;:dXXXddxxxkkkkkkOOOOOOOOOOOOOO00KXXXK00OddxxdddokxdxxdddoxkdxxdddodK0KKXXXKK0:\n xkkkOKKKxOKKXXX0KKKKKKKKKKKKKKKKKKKKKKKKO0KXXXK00KOO0OkxxxK0O00OkxxOKO00Okxxx00KKXXXKK0:\n kOOO0XXXk0XXKKKO0KKKKKKKKKKKKKKKKKKKKKKKO0KXXXK00KO0XK0OkxK0OXX0OkxOKOKXKKKK000KKXXXKK0c\n xkkk0NNl   .00k     lOOOOOOOOOOOOOOOOOOOO0KXXXK0OOk0XK0OkxOkOXX0OkxkOOKXXXXXXKK0KXXXKK0:\n oddd:       ,k      ,xxkkOO00KKXXXXKK0OOO0KXXXK0Oxk0XK0OkxxkOXX0OkxxxOKXKKKXXXXKK0XXKK0:\n                     ,xxkkOO00KKXXXXKK0OOO0KXXXK0Oxk0XK0OkxxkOXX0OkxxxOKXK000KXXXKKKXKK0:\n                     ,xxkkOO00KKXXXXKK0OOO0KXXXK0Oxk0XK0OkxxkOXX0OkxxxOKXK0k0KKXXXK0XKK0:\n                     ,xxkkOO00KKXXXXKK0OOO0KKXXK0Okk0XK0OkxkkOKK0OkxxkOKXK0O0KXXXKK0XKK0:\n                     ,xxkkOO00KKXXXXKK0OOO00KXXXXKK00000000000000000000000KKKXXXXK0XXKK0:\n                     ,xxkkOO00KKXXXXKK0OOkk00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0KXXKK0:\n                     ,xxkkOO00KKXXXXKK00OOkKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KXXXKK0:\n                     'xxkkOO00KKXXXXKK00OOOKXXKK000O0K00OOOOO00K00OOOOO0K000OOXKKKXXXKK0:\n                     .xxkkOO00KKXXXXKK00OOO0XXXXKK0O0XK0OkxOOOXX0OkxkOOKXK0kxkX0KKXXXKK0:\n                      oxxkOO00KKXXXXXKK000OOKXXXXXXKKXK0OOKKKKXX0OO0KKKKXK0OOKK0KXXXXK00,\n                       xxkkOO00KKXXXXKKK000OOKKKXXXXXXXXXXXXXXXXXXXXXXXXXXKKK00KKXXXXK00\n                       .xkkkOO00KKXXXXXKKK00OO000KKKKKKKKKKKKKKKKKKKKKKKKK0000KKXXXXKK0,\n                        .xkkOO000KKXXXXXKKKK00OOOOO000000000000000000000OO000KKXXXXKK0l\n                          xkkOO000KKXXXXXXXKKKK00OOkkkkkkkkkkkkkkkkkkkkOO00KKXXXXXKK0:\n                           ,kkOOO00KKKXXXXXXXXXKKKK000000000000000000000KKKXXXXXKK00.\n                             ;kkOO000KKKXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKXXXXXXXXKK00;\n                                oOOO0000KKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK0O\n                                   .OOO00000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00d\n                                         .x000000000000000000000000000d\n"

module Tuba::Server
  struct AnalyticsPostBody
    include JSON::Serializable

    property accounts : Array(String)

    @[JSON::Field(converter: String::RawConverter)]
    property analytics : String
  end

  VERSION = {{read_file("#{__DIR__}/../shard.yml").split("version: ")[1].split("\n")[0]}}

  get "/v1/version" do
    VERSION
  end

  get "/v1/ping" do |env|
    env.response.content_type = "text/plain"
    res = "pong"
    if env.params.query["token"]? == CONFIG.token
      res = <<-TEXT
      #{res}
      Running for: #{Time.utc - UPTIMER}
      Database size: #{File.exists?(CONFIG.database) ? File.size(CONFIG.database) : "0"}
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
