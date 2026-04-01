require "spec_helper"
require "base64"

RSpec.describe StateSync::GithubFetcher do
  let(:config) do
    StateSync::Configuration.new.tap do |c|
      c.repo  = "owner/repo"
      c.token = "ghp_testtoken"
    end
  end

  subject(:fetcher) { described_class.new(config) }

  let(:api_url)         { "https://api.github.com/repos/owner/repo/contents/config/flags.yml" }
  let(:yaml_content)    { "feature_x: true\ncustomer_ids:\n  - 1\n  - 2\n" }
  let(:encoded_content) { Base64.encode64(yaml_content) }

  describe "#fetch" do
    context "with a successful response" do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: { encoding: "base64", content: encoded_content }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the decoded file content" do
        expect(fetcher.fetch("config/flags.yml")).to eq yaml_content
      end

      it "sends the Authorization header" do
        fetcher.fetch("config/flags.yml")
        expect(WebMock).to have_requested(:get, api_url)
          .with(headers: { "Authorization" => "Bearer ghp_testtoken" })
      end
    end

    context "when the token is absent (public repo)" do
      before do
        config.token = nil
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: { encoding: "base64", content: encoded_content }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "does not send an Authorization header" do
        fetcher.fetch("config/flags.yml")
        expect(WebMock).to have_requested(:get, api_url)
          .with { |req| !req.headers.key?("Authorization") }
      end
    end

    context "when the file is not found (404)" do
      before { stub_request(:get, api_url).to_return(status: 404, body: "Not Found") }

      it "raises FetchError" do
        expect { fetcher.fetch("config/flags.yml") }
          .to raise_error(StateSync::FetchError, /File not found/)
      end
    end

    context "when authentication fails (401)" do
      before { stub_request(:get, api_url).to_return(status: 401, body: "Unauthorized") }

      it "raises FetchError" do
        expect { fetcher.fetch("config/flags.yml") }
          .to raise_error(StateSync::FetchError, /authentication failed/)
      end
    end

    context "when access is forbidden (403)" do
      before { stub_request(:get, api_url).to_return(status: 403, body: "Forbidden") }

      it "raises FetchError" do
        expect { fetcher.fetch("config/flags.yml") }
          .to raise_error(StateSync::FetchError, /forbidden/)
      end
    end
  end
end
