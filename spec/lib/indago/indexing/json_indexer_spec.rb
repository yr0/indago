describe Indago::Indexing::JsonIndexer do
  include_context :json_indexing
  subject { described_class.new(collection_name, raw_json) }

  describe '#initialize' do
    it 'stores initial values in instance variables' do
      [['collection_name', collection_name], ['raw_json', raw_json], ['array_from_json', []],
       ['values_search_tree', {}], ['basic_data', {}],
       ['index_dir', File.join(Indago::INDEXES_DIR_PATH, collection_name)]].each do |name, value|
        expect(subject.instance_variable_get("@#{name}")).to(eq(value), "`#{name}` is not set to '#{value}'")
      end
    end
  end

  describe '#call' do
    include_context :no_actual_indexing, 'json'

    it 'calls #parse_and_check_raw! within #call' do
      allow(subject).to receive(:parse_and_check_raw!)
      subject.call
      expect(subject).to have_received(:parse_and_check_raw!)
    end

    it 'calls #do_index within #call' do
      allow(subject).to receive(:do_index)
      subject.call
      expect(subject).to have_received(:do_index)
    end
  end

  describe '#parse_and_check_raw! within #call' do
    include_context :no_actual_indexing, 'json'

    context 'with non-json provided' do
      let(:raw_json) { read_fixture_file('bad.json') }

      it 'raises JSON::ParserError' do
        expect { subject.send(:parse_and_check_raw!) }.to raise_error(JSON::ParserError)
      end

      it 'handles error with logger on call' do
        with_stubbed_logger do |logger|
          subject.call
          expect(logger).to have_received(:fatal).with(/#{collection_name}.+could not be parsed/)
          expect(logger).to have_received(:fatal).with(/unexpected token/)
        end
      end
    end

    context 'with non-array json provided' do
      let(:raw_json) { read_fixture_file('no_array.json') }

      it 'raises ArrayNotProvided error' do
        expect { subject.send(:parse_and_check_raw!) }.to raise_error(Indago::Indexing::JsonIndexer::ArrayNotProvided)
      end

      it 'handles error with logger on call' do
        with_stubbed_logger do |logger|
          subject.call
          expect(logger).to have_received(:fatal).with(/#{collection_name}.+is not an array/)
        end
      end
    end

    context 'with too big array' do
      before(:each) do
        stub_const('Indago::MAX_INDEXING_ARRAY_SIZE', 10)
      end

      it 'raises ArrayTooLarge error' do
        expect { subject.send(:parse_and_check_raw!) }.to raise_error(Indago::Indexing::JsonIndexer::ArrayTooLarge)
      end

      it 'handles error with logger on call' do
        with_stubbed_logger do |logger|
          subject.call
          expect(logger).to have_received(:fatal).with(/#{collection_name}.+is too large/)
        end
      end
    end
  end
end
