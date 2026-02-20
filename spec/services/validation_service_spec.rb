# frozen_string_literal: true

RSpec.describe DiscourseIndisposableEmail::ValidationService do
  let(:accept_test_tld) do
    validator =
      instance_double(
        "DiscourseIndisposableEmail::EmailAddressValidator",
        allowed_address?: :deny,
        enabled?: true
      )
    allow(validator).to receive(:allowed_address?) { |email|
      /.*\.test/.match?(email) ? :allow : :deny
    }
    validator
  end

  let(:disabled_validator) do
    instance_double(
      "DiscourseIndisposableEmail::EmailAddressValidator",
      enabled?: false
    )
  end

  it "will validate an email address" do
    described_class.validators = [disabled_validator, accept_test_tld]

    res = described_class.allowed?("foo@example.test")
    expect(res).to be(true)

    res = described_class.allowed?("foo@example.disposable")
    expect(res).to be(false)
  end

  it "none will pass" do
    described_class.validators = []

    res = described_class.allowed?("foo@anything")
    expect(res).to be(true)
  end
end
