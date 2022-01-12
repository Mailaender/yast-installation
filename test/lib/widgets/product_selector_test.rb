require_relative "../../test_helper"

require "cwm/rspec"

require "y2packager/product_spec"
require "installation/widgets/product_selector"

describe ::Installation::Widgets::ProductSelector do
  let(:product1) do
    Y2Packager::ProductSpec.new(name: "test1", display_name: "Test 1", version: "15",
      arch: "x86_64")
  end
  let(:product2) do
    Y2Packager::ProductSpec.new(name: "test2", display_name: "Test 2", version: "15",
      arch: "x86_64")
  end
  subject { described_class.new([product1, product2]) }

  include_examples "CWM::RadioButtons"

  before do
    allow(Y2Packager::MediumType).to receive(:offline?).and_return(false)
  end

  describe "#init" do
    let(:registration) { double("Registration::Registration", is_registered?: registered?) }

    before do
      stub_const("Registration::Registration", registration)
      allow(subject).to receive(:require).with("registration/registration")
    end

    context "when the system is registered" do
      let(:registered?) { true }

      it "disables the widget" do
        expect(subject).to receive(:disable)
        subject.init
      end
    end

    context "when the system is not registered" do
      let(:registered?) { false }

      it "does not disable the widget" do
        expect(subject).to_not receive(:disable)
        subject.init
      end
    end

    context "when registration is not available" do
      let(:registered?) { false }

      before do
        allow(subject).to receive(:require).with("registration/registration")
          .and_raise(LoadError)
      end

      it "does not disable the widget" do
        expect(subject).to_not receive(:disable)
        subject.init
      end
    end

    context "when an offline base product has been selected" do
      let(:registered?) { false }

      before do
        expect(Y2Packager::MediumType).to receive(:offline?).and_return(true)
        expect(product1).to receive(:selected?).and_return(true).at_least(:once)
      end

      it "disables the widget" do
        expect(subject).to receive(:disable)
        subject.init
      end
    end
  end

  describe "#store" do
    before do
      allow(Yast::Pkg).to receive(:PkgApplReset)
      allow(Yast::Pkg).to receive(:PkgReset)
      allow(Yast::AddOnProduct).to receive(:selected_installation_products)
        .and_return(["add-on-product"])
      # mock selecting the first product
      allow(subject).to receive(:value).and_return("test1-15-x86_64")
    end

    it "selects the product to install" do
      expect(product1).to receive(:select)
      expect(product2).to_not receive(:select)
      subject.store
    end

    context "when the product was already selected" do
      before do
        allow(product1).to receive(:selected?).and_return(true)
      end

      it "does not select the product again" do
        expect(product1).to_not receive(:select)
        subject.store
      end
    end
  end
end
