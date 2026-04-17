require "spec_helper"

FIXTURES = File.expand_path("../fixtures", __dir__)

def fixture(name)
  File.read(File.join(FIXTURES, name))
end

RSpec.describe StateSync::Store, "YAML type handling" do
  def configure(data_format: :struct)
    StateSync.configure do |c|
      c.repo         = "owner/repo"
      c.token        = "ghp_test"
      c.auto_refresh = false
      c.data_format  = data_format
    end
  end

  def store_for(fixture_name)
    allow_any_instance_of(StateSync::GithubFetcher)
      .to receive(:fetch)
      .and_return(fixture(fixture_name))
    StateSync::Store.new("config/file.yml")
  end

  # ---------------------------------------------------------------------------
  # Hash roots
  # ---------------------------------------------------------------------------

  context "hash_simple.yml — flat Hash" do
    context "data_format: :struct (default)" do
      before { configure }
      subject(:store) { store_for("hash_simple.yml") }

      it "returns a DataNode" do
        expect(store.data).to be_a(StateSync::DataNode)
      end

      it "exposes keys via dot-access" do
        expect(store.data.name).to eq "my_app"
        expect(store.data.env).to eq "production"
        expect(store.data.max_connections).to eq 10
      end

      it "exposes keys via []" do
        expect(store["version"]).to eq "1.0.0"
      end
    end

    context "data_format: :hash" do
      before { configure(data_format: :hash) }
      subject(:store) { store_for("hash_simple.yml") }

      it "returns a plain Hash" do
        expect(store.data).to be_a(Hash)
      end

      it "exposes string-keyed values" do
        expect(store.data["name"]).to eq "my_app"
        expect(store["version"]).to eq "1.0.0"
      end
    end
  end

  context "hash_nested.yml — deeply nested Hash" do
    context "data_format: :struct" do
      before { configure }
      subject(:store) { store_for("hash_nested.yml") }

      it "recursively wraps nested hashes in DataNode" do
        expect(store.data.app).to be_a(StateSync::DataNode)
        expect(store.data.app.settings.advanced).to be_a(StateSync::DataNode)
      end

      it "resolves deeply nested values" do
        expect(store.data.app.settings.theme).to eq "dark"
        expect(store.data.app.settings.advanced.ttl).to eq 3600
        expect(store.data.database.port).to eq 5432
      end
    end

    context "data_format: :hash" do
      before { configure(data_format: :hash) }
      subject(:store) { store_for("hash_nested.yml") }

      it "returns a plain nested Hash" do
        expect(store.data["app"]).to be_a(Hash)
        expect(store.data["app"]["settings"]["advanced"]["ttl"]).to eq 3600
      end
    end
  end

  context "hash_with_arrays.yml — Hash with Array values" do
    context "data_format: :struct" do
      before { configure }
      subject(:store) { store_for("hash_with_arrays.yml") }

      it "returns scalar arrays as plain Arrays" do
        expect(store.data.tags).to eq %w[ruby yaml config]
        expect(store.data.scores).to eq [95, 87, 100]
      end

      it "wraps Hash elements inside arrays in DataNode" do
        expect(store.data.admins.first).to be_a(StateSync::DataNode)
        expect(store.data.admins.first.name).to eq "Alice"
        expect(store.data.admins.last.role).to eq "admin"
      end
    end

    context "data_format: :hash" do
      before { configure(data_format: :hash) }
      subject(:store) { store_for("hash_with_arrays.yml") }

      it "returns plain Array values with plain Hash elements" do
        expect(store.data["admins"].first).to be_a(Hash)
        expect(store.data["admins"].first["name"]).to eq "Alice"
      end
    end
  end

  context "hash_all_scalars.yml — every scalar type as a value" do
    before { configure }
    subject(:store) { store_for("hash_all_scalars.yml") }

    it "preserves strings" do
      expect(store.data.a_string).to eq "hello world"
      expect(store.data.a_quoted_string).to eq "with spaces and special chars: !@#"
    end

    it "preserves integers" do
      expect(store.data.an_integer).to eq 42
      expect(store.data.a_negative_integer).to eq(-7)
    end

    it "preserves floats" do
      expect(store.data.a_float).to eq 3.14
      expect(store.data.a_negative_float).to eq(-0.5)
    end

    it "preserves booleans" do
      expect(store.data.a_true).to be true
      expect(store.data.a_false).to be false
    end

    it "preserves nulls" do
      expect(store.data.a_null_keyword).to be_nil
      expect(store.data.a_null_tilde).to be_nil
    end

    it "keeps date/datetime as strings (YAML.safe_load does not auto-parse Date/Time)" do
      expect(store.data.a_date_string).to eq "2024-01-15"
      expect(store.data.a_datetime_string).to eq "2024-01-15T10:30:00Z"
    end
  end

  context "hash_multiline.yml — block scalar strings" do
    before { configure }
    subject(:store) { store_for("hash_multiline.yml") }

    it "collapses folded block into one line" do
      expect(store.data.folded).to eq "this is a folded block string that becomes one line\n"
    end

    it "preserves newlines in literal block" do
      expect(store.data.literal).to eq "this is a literal\nblock string that\nkeeps its newlines\n"
    end

    it "strips trailing newline with folded-strip" do
      expect(store.data.folded_strip).to eq "no trailing newline after this one"
    end
  end

  context "hash_anchors.yml — anchor-equivalent expanded Hash" do
    before { configure }
    subject(:store) { store_for("hash_anchors.yml") }

    it "exposes shared and overridden keys" do
      expect(store.data.production.timeout).to eq 30
      expect(store.data.production.log_level).to eq "error"
      expect(store.data.staging.log_level).to eq "warn"
      expect(store.data.staging.host).to eq "staging.example.com"
    end
  end

  # ---------------------------------------------------------------------------
  # Array roots
  # ---------------------------------------------------------------------------

  context "array_of_scalars.yml — root is Array of scalars" do
    subject(:store) { store_for("array_of_scalars.yml") }

    context "data_format: :struct" do
      before { configure }

      it "returns a plain Array (scalars are never wrapped)" do
        expect(store.data).to eq ["apple", "banana", "cherry", 42, true]
      end
    end

    context "data_format: :hash" do
      before { configure(data_format: :hash) }

      it "returns the same plain Array" do
        expect(store.data).to eq ["apple", "banana", "cherry", 42, true]
      end
    end
  end

  context "array_of_hashes.yml — root is Array of Hashes" do
    context "data_format: :struct" do
      before { configure }
      subject(:store) { store_for("array_of_hashes.yml") }

      it "returns an Array of DataNodes" do
        expect(store.data.first).to be_a(StateSync::DataNode)
      end

      it "allows dot-access on each element" do
        expect(store.data[0].name).to eq "Alice"
        expect(store.data[1].age).to eq 25
        expect(store.data[2].active).to be true
      end
    end

    context "data_format: :hash" do
      before { configure(data_format: :hash) }
      subject(:store) { store_for("array_of_hashes.yml") }

      it "returns an Array of plain Hashes" do
        expect(store.data.first).to be_a(Hash)
        expect(store.data.first["name"]).to eq "Alice"
        expect(store.data.last["active"]).to be true
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Scalar roots — same result regardless of data_format
  # ---------------------------------------------------------------------------

  context "scalar_string.yml — root is a String" do
    before { configure }
    subject(:store) { store_for("scalar_string.yml") }

    it "returns the raw String" do
      expect(store.data).to eq "just a plain string at the root"
    end
  end

  context "scalar_integer.yml — root is an Integer" do
    before { configure }
    subject(:store) { store_for("scalar_integer.yml") }

    it "returns the raw Integer" do
      expect(store.data).to eq 99
    end
  end

  context "scalar_boolean.yml — root is a Boolean" do
    before { configure }
    subject(:store) { store_for("scalar_boolean.yml") }

    it "returns true" do
      expect(store.data).to be true
    end
  end

  context "scalar_null.yml — root is null" do
    before { configure }
    subject(:store) { store_for("scalar_null.yml") }

    it "returns nil" do
      expect(store.data).to be_nil
    end
  end
end
