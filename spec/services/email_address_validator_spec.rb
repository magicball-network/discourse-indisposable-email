# frozen_string_literal: true

RSpec.describe DiscourseIndisposableEmail::EmailAddressValidator do
  let(:validator) { described_class.new }

  it "returns the domain part of an email" do
    expect(validator.get_domain("foo@Example.Test")).to eq("example.test")
    expect(validator.get_domain("nothing")).to eq("")
    expect(validator.get_domain("")).to eq("")
    expect(validator.get_domain(nil)).to eq("")
  end

  it "returns failure on missing domain" do
    expect(validator.allowed_address?("nothing")).to eq(:failure)
    expect(validator.allowed_address?("")).to eq(:failure)
    expect(validator.allowed_address?(nil)).to eq(:failure)
  end

  it "returns the cached result" do
    Discourse.cache.write("DIE::allow.test", :allow)
    Discourse.cache.write("DIE::deny.test", :deny)

    expect(validator.allowed_address?("foo@allow.test")).to eq(:allow)
    expect(validator.allowed_address?("foo@deny.test")).to eq(:deny)
    expect(validator.allowed_address?("foo@failure.test")).to eq(:failure)
  end

  it "persists the cache on success" do
    allow(Discourse.cache).to receive(:write)

    cls =
      Class.new(described_class) do
        def retrieve_status(domain)
          :allow
        end
      end
    validator = cls.new

    result = validator.allowed_address?("foo@allow.test")
    expect(result).to eq(:allow)
    expect(Discourse.cache).to have_received(:write).with(
      "DIE::allow.test",
      :allow
    )
  end
end
