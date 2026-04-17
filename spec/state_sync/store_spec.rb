require "spec_helper"
require "base64"

RSpec.describe StateSync::Store do
  let(:yaml_content) { "customer_ids:\n  - 1\n  - 2\n  - 3\nfeature_x: true\n" }
  let(:encoded)      { Base64.encode64(yaml_content) }
  let(:api_url)      { "https://api.github.com/repos/owner/repo/contents/config/customers.yml" }

  before do
    StateSync.configure do |c|
      c.repo         = "owner/repo"
      c.token        = "ghp_test"
      c.auto_refresh = false
    end

    stub_request(:get, api_url)
      .to_return(
        status: 200,
        body: { encoding: "base64", content: encoded }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  subject(:store) { described_class.new("config/customers.yml") }

  describe "#data" do
    it "returns a DataNode" do
      expect(store.data).to be_a(StateSync::DataNode)
    end

    it "exposes top-level keys as methods" do
      expect(store.data.customer_ids).to eq [1, 2, 3]
      expect(store.data.feature_x).to be true
    end
  end

  describe "#[]" do
    it "provides shorthand key access" do
      expect(store["customer_ids"]).to eq [1, 2, 3]
      expect(store["feature_x"]).to be true
    end
  end

  describe "#reload!" do
    let(:updated_yaml) { "customer_ids:\n  - 1\n  - 2\n  - 3\n  - 4\n" }

    before do
      stub_request(:get, api_url)
        .to_return(
          { status: 200, body: { encoding: "base64", content: encoded }.to_json,
            headers: { "Content-Type" => "application/json" } },
          { status: 200, body: { encoding: "base64", content: Base64.encode64(updated_yaml) }.to_json,
            headers: { "Content-Type" => "application/json" } }
        )
    end

    it "re-fetches and updates the data" do
      expect(store["customer_ids"]).to eq [1, 2, 3]
      store.reload!
      expect(store["customer_ids"]).to eq [1, 2, 3, 4]
    end

    it "returns self" do
      expect(store.reload!).to be store
    end
  end

  describe "with gitlab provider" do
    let(:gitlab_url) do
      "https://gitlab.com/api/v4/projects/owner%2Frepo/repository/files/config%2Fcustomers.yml/raw?ref=HEAD"
    end

    before do
      StateSync.instance_variable_set(:@configuration, nil)
      StateSync.configure do |c|
        c.provider     = :gitlab
        c.repo         = "owner/repo"
        c.token        = "glpat_test"
        c.auto_refresh = false
      end

      stub_request(:get, gitlab_url)
        .to_return(status: 200, body: yaml_content)
    end

    it "fetches from gitlab and returns a DataNode" do
      expect(store.data).to be_a(StateSync::DataNode)
      expect(store.data.customer_ids).to eq [1, 2, 3]
      expect(store.data.feature_x).to be true
    end
  end
end
