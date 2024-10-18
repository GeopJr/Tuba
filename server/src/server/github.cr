require "uri"
require "http/client"

class Tuba::GitHubSupporters
  PROVIDERS = {"MASTODON", "HOMETOWN", "GENERIC"}

  struct SocialAccountNode
    include JSON::Serializable

    property url : String
    property provider : String
  end

  struct SocialAccountEdges
    include JSON::Serializable

    property node : SocialAccountNode
  end

  struct SocialAccount
    include JSON::Serializable

    property edges : Array(SocialAccountEdges)
  end

  struct SponsorsNode
    include JSON::Serializable

    property socialAccounts : SocialAccount
    property name : String?
    property login : String
    property websiteUrl : String?
  end

  struct SponsorsEdges
    include JSON::Serializable

    property cursor : String
    property node : SponsorsNode
  end

  struct Sponsors
    include JSON::Serializable

    property edges : Array(SponsorsEdges?)
  end

  struct SponsorViewer
    include JSON::Serializable

    property sponsors : Sponsors
  end

  struct SponsorsData
    include JSON::Serializable

    property viewer : SponsorViewer
  end

  struct SponsorsResponse
    include JSON::Serializable

    property data : SponsorsData
  end

  struct ContributorsRest
    include JSON::Serializable

    property login : String
  end

  struct ContributorsResponse
    include JSON::Serializable

    property data : Hash(String, SponsorsNode)
  end

  @cursor : String? = nil

  def initialize(@github_token : String = CONFIG.github)
  end

  private def sponsors_query : String
    cursor_str = @cursor.nil? ? "" : ", after: \"#{@cursor}\""

    <<-GRAPHQL
      query SponsorQuery {
        viewer {
          sponsors(first: 100#{cursor_str}) {
            edges {
              cursor
              node {
                ... on User {
                  socialAccounts(first: 100) {
                      edges {
                          node {
                              ... on SocialAccount {
                                  url
                                  provider
                              }
                          }
                      }
                  }
                  name
                  login
                  websiteUrl
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  private def contributors_query(contributors : Array(String)) : String
    users = [] of String
    contributors.each_with_index do |contributor, i|
      users << <<-GRAPHQL
        user#{i}: user(login: "#{contributor}") {
          ...UserFragment
        }
      GRAPHQL
    end

    <<-GRAPHQL
      query {
        #{users.join("\n")}
      }

      fragment UserFragment on User {
        login
        name
        socialAccounts(first: 100) {
            edges {
                node {
                    ... on SocialAccount {
                        url
                        provider
                    }
                }
            }
        }
      }
    GRAPHQL
  end

  def gather_contributors : Array(String)
    res = [] of String

    response = HTTP::Client.get("https://api.github.com/repos/GeopJr/Tuba/contributors?per_page=100&page=1",
      headers: HTTP::Headers{
        "Content-Type"  => "application/json",
        "Accept"        => "Accept: application/vnd.github+json",
        "Authorization" => "Bearer #{@github_token}",
      }
    )

    unless response.success?
      Log.info { "GitHub API response: #{response.status}\n#{response.body}" }
      return res
    end

    response = HTTP::Client.post("https://api.github.com/graphql",
      body: {query: contributors_query(Array(ContributorsRest).from_json(response.body).map(&.login))}.to_json,
      headers: HTTP::Headers{
        "Content-Type"  => "application/json",
        "Accept"        => "application/json",
        "Authorization" => "token #{@github_token}",
      }
    )

    unless response.success?
      Log.info { "GitHub API response: #{response.status}\n#{response.body}" }
      return res
    end

    ContributorsResponse.from_json(response.body).data.values.each do |contributor|
      contributor.socialAccounts.edges.each do |social_account|
        next unless PROVIDERS.includes?(social_account.node.provider)
        handle = url_to_hash(social_account.node.url)
        next if handle.nil?

        res << handle
      end
    end

    res
  end

  def gather_sponsors : Array(String)
    res = [] of String

    loop do
      response = HTTP::Client.post("https://api.github.com/graphql",
        body: {query: sponsors_query()}.to_json,
        headers: HTTP::Headers{
          "Content-Type"  => "application/json",
          "Accept"        => "application/json",
          "Authorization" => "token #{@github_token}",
        }
      )
      @cursor = nil

      unless response.success?
        Log.info { "GitHub API response: #{response.status}\n#{response.body}" }
        break
      end

      SponsorsResponse.from_json(response.body).data.viewer.sponsors.edges.each do |sponsor|
        next if sponsor.nil?

        @cursor = sponsor.cursor
        sponsor.node.socialAccounts.edges.each do |social_account|
          next unless PROVIDERS.includes?(social_account.node.provider)
          handle = url_to_hash(social_account.node.url)
          next if handle.nil?

          res << handle
        end
      end

      break if @cursor.nil?
    end

    res
  end

  def gather : Array(String)
    gather_sponsors.concat(gather_contributors).uniq!
  end

  private def url_to_hash(url : String) : String?
    uri = URI.parse(url)
    uri_path = uri.path
    return nil if uri_path.nil? || uri_path == ""
    handle = uri_path[1..-1]
    return nil if handle.includes?('/') || !handle.includes?('@')

    if handle.count('@') == 1
      if handle.starts_with?('@')
        handle = "#{handle}@#{uri.host}"
      else
        handle = "@#{handle}"
      end
    end

    hashed = 5381_u32
    handle.downcase.each_byte do |byte|
      hashed = (hashed << 5) &+ hashed &+ byte
    end

    hashed.to_s
  end
end
