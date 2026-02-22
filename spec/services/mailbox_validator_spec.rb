# frozen_string_literal: true

RSpec.describe DiscourseIndisposableEmail::MailboxValidator do
  let(:validator) { described_class.new }

  before(:example) do
    SiteSetting.indisposable_email_mailboxvalidator_key = "test"
  end

  it "is enabled" do
    expect(validator.enabled?).to be(true)
    SiteSetting.indisposable_email_mailboxvalidator_key = ""
    expect(validator.enabled?).to be(false)
  end

  it "resolves a disposable domain" do
    stub_request(
      :get,
      "https://api.mailboxvalidator.com/v2/email/disposable"
    ).with(
      query: {
        email: "example@dropmeon.com",
        key: "test",
        format: "json"
      }
    ).to_return(status: 200, body: die_file_fixture("mailboxvalidator.json"))

    result = validator.retrieve_status("dropmeon.com")
    expect(result).to be(:deny)
  end

  it "backs off on too many requests" do
    stub_request(
      :get,
      "https://api.mailboxvalidator.com/v2/email/disposable"
    ).with(query: hash_including({ email: "example@error429.test" })).to_return(
      status: 429
    )

    result = validator.retrieve_status("error429.test")
    expect(result).to be(:failure)
    expect(validator.enabled?).to be(false)
  end

  it "backs off when no credits" do
    stub_request(
      :get,
      "https://api.mailboxvalidator.com/v2/email/disposable"
    ).with(
      query: hash_including({ email: "example@nocredits.test" })
    ).to_return(status: 200, body: { credits_available: 0 }.to_json)

    validator.retrieve_status("nocredits.test")
    expect(validator.enabled?).to be(false)
  end

  it "backs off when running out of credits" do
    stub_request(
      :get,
      "https://api.mailboxvalidator.com/v2/email/disposable"
    ).with(
      query: hash_including({ email: "example@nocredits.test" })
    ).to_return(status: 400, body: { error: { error_code: 10_004 } }.to_json)

    result = validator.retrieve_status("nocredits.test")
    expect(result).to be(:failure)
    expect(validator.enabled?).to be(false)
  end

  it "fails on a network failure" do
    stub_request(
      :get,
      "https://api.mailboxvalidator.com/v2/email/disposable"
    ).with(query: hash_including({ email: "example@error500.test" })).to_return(
      status: 500
    )

    result = validator.retrieve_status("error500.test")
    expect(result).to be(:failure)
    expect(validator.enabled?).to be(true)
  end

  it "produces a failure on invalid json" do
    stub_request(
      :get,
      "https://api.mailboxvalidator.com/v2/email/disposable"
    ).with(query: hash_including({ email: "example@nojson.test" })).to_return(
      status: 200,
      body: "this is not json"
    )

    result = validator.retrieve_status("nojson.test")
    expect(result).to be(:failure)
  end
end
