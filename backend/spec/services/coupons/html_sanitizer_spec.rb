require "rails_helper"

RSpec.describe Coupons::HtmlSanitizer do
  it "returns nil for nil" do
    expect(described_class.sanitize(nil)).to be_nil
  end

  it "returns nil for a blank string" do
    expect(described_class.sanitize("")).to be_nil
  end

  it "strips a script tag but keeps its text content inline" do
    html = %(<p onclick="evil()">Hello <script>alert(1)</script>world</p>)
    expect(described_class.sanitize(html)).to eq("<p>Hello alert(1)world</p>")
  end

  it "strips a disallowed attribute while keeping the element" do
    html = %(<a href="javascript:evil()">link</a>)
    expect(described_class.sanitize(html)).to eq("<a>link</a>")
  end

  it "passes an already-safe fragment through unchanged" do
    expect(described_class.sanitize("<p>Save <b>10%</b> today</p>")).to eq("<p>Save <b>10%</b> today</p>")
  end
end
