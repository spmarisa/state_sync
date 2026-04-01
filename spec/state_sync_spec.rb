require "spec_helper"
require "base64"

RSpec.describe StateSync do
  let(:yaml_content) { "customer_ids:\n  - 1\n  - 2\n" }
  let(:encoded)      { Base64.encode64(yaml_content) }
  let(:api_url)      { "https://api.github.com/repos/owner/repo/contents/config/customers.yml" }

  before do
    stub_request(:get, api_url)
      .to_return(
        status: 200,
        body: { encoding: "base64", content: encoded }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".configure" do
    it "sets configuration values" do
      StateSync.configure do |c|
        c.repo  = "owner/repo"
        c.token = "ghp_test"
      end

      expect(StateSync.configuration.repo).to eq "owner/repo"
      expect(StateSync.configuration.token).to eq "ghp_test"
    end

    it "raises ConfigurationError when repo is missing" do
      expect do
        StateSync.configure { |c| }
      end.to raise_error(StateSync::ConfigurationError, /repo must be set/)
    end
  end

  describe ".load" do
    before do
      StateSync.configure do |c|
        c.repo  = "owner/repo"
        c.token = "ghp_test"
      end
    end

    it "returns a Store instance" do
      expect(StateSync.load("config/customers.yml")).to be_a(StateSync::Store)
    end

    it "fetches the file immediately" do
      StateSync.load("config/customers.yml")
      expect(WebMock).to have_requested(:get, api_url)
    end
  end
end
