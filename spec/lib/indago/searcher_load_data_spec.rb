# loading data and result
describe Indago::Searcher do
  include_context :with_real_indexes

  let(:collection_name) { 'users' }
  let(:field) { 'name' }
  let(:value) { 'Prince Hinton' }
  let(:expected_loaded_data) do
    JSON.parse File.read(File.join(Indago::INDEXES_DIR_PATH, collection_name,
                                   "#{field}#{Indago::INDEX_FILE_EXTENSION}"))
  end
  let(:expected_full_user) { JSON.parse(read_fixture_file('expected_full_user.json')) }

  subject { described_class.new(collection_name) }

  describe '#load_data_for' do
    it 'raises NoIndexError if index does not exist' do
      expect { subject.send(:load_data_for, 'java_knowledge') }.to raise_error(Indago::Searcher::NoIndexError)
    end

    it 'assigns to @stored_fields_data parsed json from index file that represents the field' do
      expect { subject.send(:load_data_for, field) }
        .to(change { subject.instance_variable_get('@stored_fields_data') }.from({})
          .to(field => expected_loaded_data))
    end
  end

  describe '#load_and_process_result' do
    it 'loads correct result with associated fields loaded' do
      expect(subject.send(:load_and_process_result, field, value)).to eq expected_full_user
    end

    context 'with stubbed load_data and relations_populator' do
      let(:default_full_records) { Array.new(5) { |n| [n.to_s, { '_id' => n }] }.to_h }
      let(:mock_relations_populator) { spy MockRelationsPopulator.new(collection_name) }
      let(:searched_record_by_id) { ['_id' => 3] }
      let(:searched_records) { [{ '_id' => 2 }, { '_id' => 4 }] }

      before(:each) do
        allow(subject).to receive(:load_data_for).and_return(default_full_records)
        subject.instance_variable_set('@relations_populator', mock_relations_populator)
      end

      it 'returns a single record if searched by id' do
        expect(subject.send(:load_and_process_result, Indago::PRIMARY_FIELD_NAME, 3)).to eq searched_record_by_id
      end

      it 'returns found records by #ids_from_tree_for if searched by other values' do
        allow(subject).to receive(:ids_from_tree_for).and_return(%w[2 4])
        result = subject.send(:load_and_process_result, field, value)
        expect(result).to eq searched_records
        expect(subject).to have_received(:ids_from_tree_for).with(field, value)
      end

      it 'calls #process on relations_populator' do
        subject.send(:load_and_process_result, field, value)
        expect(mock_relations_populator).to have_received(:process)
      end
    end
  end
end
