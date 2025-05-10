require "spec"
require "json"
require "../src/server/*"

DATABASE = Tuba::Database.new
CONFIG   = Config.from_json({
  "token"    => "test",
  "database" => "#{__DIR__}/test.db",
  "github"   => "",
}.to_json)
