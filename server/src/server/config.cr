struct Config
  include JSON::Serializable

  property token : String
  property github : String
  property database : String
end
