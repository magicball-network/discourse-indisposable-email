# frozen_string_literal: true

RSpec.describe DiscourseIndisposableEmail::ZerobounceValidator do
  let(:validator) { described_class.new }

  before(:example) { SiteSetting.indisposable_email_zerobounce_key = "test" }

  it "is enabled" do
    expect(validator.enabled?).to be(true)
    SiteSetting.indisposable_email_zerobounce_key = ""
    expect(validator.enabled?).to be(false)
  end

  it "resolves a disposable domain" do
    stub_request(:get, "https://api-eu.zerobounce.net/v2/validate").with(
      query: {
        email: "example@dropmeon.com",
        api_key: "test"
      }
    ).to_return(status: 200, body: die_file_fixture("zerobounce.json"))

    result = validator.retrieve_status("dropmeon.com")
    expect(result).to be(:deny)
  end

  it "backs off on too many requests" do
    stub_request(:get, "https://api-eu.zerobounce.net/v2/validate").with(
      query: hash_including({ email: "example@error429.test" })
    ).to_return(status: 429)

    result = validator.retrieve_status("error429.test")
    expect(result).to be(:failure)
    expect(validator.enabled?).to be(false)
  end

  it "backs off on an error reponse" do
    stub_request(:get, "https://api-eu.zerobounce.net/v2/validate").with(
      query: hash_including({ email: "example@errorbody.test" })
    ).to_return(status: 200, body: "{\"error\": \"some error\"}")

    result = validator.retrieve_status("errorbody.test")
    expect(result).to be(:failure)
    expect(validator.enabled?).to be(false)
  end

  it "fails on a network failure" do
    stub_request(:get, "https://api-eu.zerobounce.net/v2/validate").with(
      query: hash_including({ email: "example@error500.test" })
    ).to_return(status: 500)

    result = validator.retrieve_status("error500.test")
    expect(result).to be(:failure)
    expect(validator.enabled?).to be(true)
  end

  it "produces a failure on invalid json" do
    stub_request(:get, "https://api-eu.zerobounce.net/v2/validate").with(
      query: hash_including({ email: "example@nojson.test" })
    ).to_return(status: 200, body: "this is not json")

    result = validator.retrieve_status("nojson.test")
    expect(result).to be(:failure)
  end
end
