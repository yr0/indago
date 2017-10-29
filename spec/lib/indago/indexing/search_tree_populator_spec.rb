describe Indago::Indexing::SearchTreePopulator do
  include_context :json_indexing

  let(:search_tree) { {} }
  let(:basic_data) { {} }
  let(:item) { parsed_json.first }

  subject do
    described_class.new(search_tree: search_tree, item: item, basic_data: basic_data, collection_name: collection_name)
  end

  describe '#initialize' do
    it 'stores initial data in instance variables' do
      %i[search_tree item basic_data collection_name].each do |name|
        value = send(name)
        expect(subject.instance_variable_get("@#{name}")).to(eq(value), "`#{name}` is not set to '#{value}'")
      end
    end
  end

  describe '#call' do
    before(:each) do
      allow(subject).to receive(:populate_tree_with)
    end

    it 'extracts item id from item and populates @item_id with it' do
      item_id_from_json = item['_id']
      expect(item_id_from_json).to_not be_nil
      expect { subject.call }
        .to change { subject.instance_variable_get('@item_id') }.from(nil).to(item_id_from_json.to_s)
    end

    context 'with json without id' do
      let(:raw_json) { read_fixture_file('one_user_no_id.json') }

      it 'provides a warning and does not proceed with item processing if no item id is found' do
        with_stubbed_logger do |logger|
          subject.call
          expect(logger).to have_received(:warn).with(/#{@item} does not have #{Indago::PRIMARY_FIELD_NAME}/)
          expect(subject).not_to have_received(:populate_tree_with)
        end
      end
    end

    context 'with simpler json representation' do
      let(:parsed_json) { [{ '_id' => 2 }] }

      it 'iterates over every key-value pair of item and calls populate_tree_with with it' do
        subject.call
        expect(subject).to have_received(:populate_tree_with).with('_id', 2)
      end
    end
  end
end
