# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe Gitlab::Ci::Config::Entry::Include::Rules::Rule, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class).value(config)
  end

  subject(:entry) { factory.create! }

  before do
    entry.compose!
  end

  shared_examples 'a valid config' do
    it { is_expected.to be_valid }

    it 'returns the expected value' do
      expect(entry.value).to eq(config.compact)
    end
  end

  shared_examples 'an invalid config' do |error_message|
    it { is_expected.not_to be_valid }

    it 'has errors' do
      expect(entry.errors).to include(error_message)
    end
  end

  context 'when specifying an if: clause' do
    let(:config) { { if: '$THIS || $THAT' } }

    it_behaves_like 'a valid config'

    context 'with when:' do
      let(:config) { { if: '$THIS || $THAT', when: 'never' } }

      it_behaves_like 'a valid config'
    end

    context 'with when: <invalid string>' do
      let(:config) { { if: '$THIS || $THAT', when: 'on_success' } }

      it_behaves_like 'an invalid config', /when unknown value: on_success/
    end

    context 'with when: null' do
      let(:config) { { if: '$THIS || $THAT', when: nil } }

      it_behaves_like 'a valid config'
    end

    context 'when if: clause is invalid' do
      let(:config) { { if: '$MY_VAR ==' } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when if: clause has an integer operand' do
      let(:config) { { if: '$MY_VAR == 123' } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when if: clause has invalid regex' do
      let(:config) { { if: '$MY_VAR =~ /some ( thing/' } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when if: clause has lookahead regex character "?"' do
      let(:config) { { if: '$CI_COMMIT_REF =~ /^(?!master).+/' } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when if: clause has array of expressions' do
      let(:config) { { if: ['$MY_VAR == "this"', '$YOUR_VAR == "that"'] } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end
  end

  context 'when specifying an exists: clause' do
    let(:config) { { exists: './this.md' } }

    it_behaves_like 'a valid config'

    context 'when array' do
      let(:config) { { exists: ['./this.md', './that.md'] } }

      it_behaves_like 'a valid config'
    end

    context 'when null' do
      let(:config) { { exists: nil } }

      it_behaves_like 'a valid config'
    end
  end

  context 'when specifying an unknown keyword' do
    let(:config) { { invalid: :something } }

    it_behaves_like 'an invalid config', /unknown keys: invalid/
  end

  context 'when config is blank' do
    let(:config) { {} }

    it_behaves_like 'an invalid config', /can't be blank/
  end

  context 'when config type is invalid' do
    let(:config) { 'invalid' }

    it_behaves_like 'an invalid config', /should be a hash/
  end
end
