require "spec_helper"

RSpec.describe StateSync::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it { expect(config.provider).to eq :github }
    it { expect(config.token).to be_nil }
    it { expect(config.repo).to be_nil }
    it { expect(config.data_format).to eq :struct }
  end

  describe "#validate!" do
    context "when repo is missing" do
      it "raises ConfigurationError" do
        expect { config.validate! }.to raise_error(StateSync::ConfigurationError, /repo must be set/)
      end
    end

    context "when provider is invalid" do
      before { config.repo = "owner/repo" }

      it "raises ConfigurationError" do
        config.provider = :bitbucket
        expect { config.validate! }.to raise_error(StateSync::ConfigurationError, /provider must be :github or :gitlab/)
      end
    end

    context "when valid with github" do
      before { config.repo = "owner/repo" }

      it "does not raise" do
        expect { config.validate! }.not_to raise_error
      end
    end

    context "when valid with gitlab" do
      before do
        config.repo     = "owner/repo"
        config.provider = :gitlab
      end

      it "does not raise" do
        expect { config.validate! }.not_to raise_error
      end
    end

    context "when data_format is invalid" do
      before { config.repo = "owner/repo" }

      it "raises ConfigurationError" do
        config.data_format = :xml
        expect { config.validate! }.to raise_error(StateSync::ConfigurationError, /data_format must be :struct or :hash/)
      end
    end

    context "when data_format is :hash" do
      before do
        config.repo        = "owner/repo"
        config.data_format = :hash
      end

      it "does not raise" do
        expect { config.validate! }.not_to raise_error
      end
    end
  end
end
