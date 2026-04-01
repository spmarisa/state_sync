require "net/http"
require "uri"
require "json"
require "base64"

class StateSync::GithubFetcher
  API_BASE = "https://api.github.com"

  def initialize(config)
    @config = config
  end

  # Fetches raw file content (string) from GitHub.
  # No ?ref= param — GitHub uses the repo's default branch automatically.
  def fetch(path)
    uri = URI("#{API_BASE}/repos/#{@config.repo}/contents/#{path}")

    request = Net::HTTP::Get.new(uri)
    request["Accept"]               = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"
    request["Authorization"]        = "Bearer #{@config.token}" if @config.token

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response, path)
  end

  private

  def handle_response(response, path)
    case response.code.to_i
    when 200
      json = JSON.parse(response.body)

      if json["encoding"] == "base64"
        Base64.decode64(json["content"])
      else
        raise StateSync::FetchError, "Unexpected encoding from GitHub: #{json["encoding"]}"
      end
    when 401
      raise StateSync::FetchError, "GitHub authentication failed — check your github_token."
    when 403
      raise StateSync::FetchError, "GitHub access forbidden — ensure your token has 'Contents' read permission."
    when 404
      raise StateSync::FetchError, "File not found: '#{path}' in repo '#{@config.repo}'. Check the path and that the repo exists."
    else
      raise StateSync::FetchError, "GitHub API returned #{response.code}: #{response.body}"
    end
  end
end
