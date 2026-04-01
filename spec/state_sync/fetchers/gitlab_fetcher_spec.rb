require "spec_helper"

RSpec.describe StateSync::GitlabFetcher do
  let(:config) do
    StateSync::Configuration.new.tap do |c|
      c.provider = :gitlab
      c.repo     = "owner/repo"
      c.token    = "glpat-testtoken"
    end
  end

  subject(:fetcher) { described_class.new(config) }

  let(:yaml_content) { "feature_x: true\ncustomer_ids:\n  - 1\n  - 2\n" }
  let(:api_url) do
    "https://gitlab.com/api/v4/projects/owner%2Frepo/repository/files/config%2Fflags.yml/raw?ref=HEAD"
  end

  describe "#fetch" do
    context "with a successful response" do
      before do
        stub_request(:get, api_url).to_return(status: 200, body: yaml_content)
      end

      it "returns the raw file content" do
        expect(fetcher.fetch("config/flags.yml")).to eq yaml_content
      end

      it "sends the PRIVATE-TOKEN header" do
        fetcher.fetch("config/flags.yml")
        expect(WebMock).to have_requested(:get, api_url)
          .with(headers: { "PRIVATE-TOKEN" => "glpat-testtoken" })
      end
    end

    context "when the token is absent (public project)" do
      before do
        config.token = nil
        stub_request(:get, api_url).to_return(status: 200, body: yaml_content)
      end

      it "does not send a PRIVATE-TOKEN header" do
        fetcher.fetch("config/flags.yml")
        expect(WebMock).to have_requested(:get, api_url)
          .with { |req| !req.headers.key?("Private-Token") }
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
