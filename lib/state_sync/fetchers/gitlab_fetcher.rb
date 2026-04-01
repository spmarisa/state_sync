require "net/http"
require "uri"

class StateSync::GitlabFetcher
  API_BASE = "https://gitlab.com/api/v4"

  def initialize(config)
    @config = config
  end

  # Fetches raw file content from GitLab using the repository files raw endpoint.
  # ref=HEAD always resolves to the project's default branch.
  def fetch(path)
    encoded_repo = URI.encode_www_form_component(@config.repo)
    encoded_path = URI.encode_www_form_component(path)
    uri = URI("#{API_BASE}/projects/#{encoded_repo}/repository/files/#{encoded_path}/raw?ref=HEAD")

    request = Net::HTTP::Get.new(uri)
    request["PRIVATE-TOKEN"] = @config.token if @config.token

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response, path)
  end

  private

  def handle_response(response, path)
    case response.code.to_i
    when 200
      response.body
    when 401
      raise StateSync::FetchError, "GitLab authentication failed — check your gitlab_token."
    when 403
      raise StateSync::FetchError, "GitLab access forbidden — ensure your token has 'read_repository' scope."
    when 404
      raise StateSync::FetchError, "File not found: '#{path}' in repo '#{@config.repo}'. Check the path and that the project exists."
    else
      raise StateSync::FetchError, "GitLab API returned #{response.code}: #{response.body}"
    end
  end
end
