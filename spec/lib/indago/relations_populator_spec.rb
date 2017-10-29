describe Indago::RelationsPopulator do
  include_context(:relations_populating)

  subject { described_class.new(collection_name) }

  describe '#initialize' do
    it 'stores initial values in instance variables' do
      [['collection_name', collection_name], ['basic_data', {}], ['searchers', {}]].each do |name, value|
        expect(subject.instance_variable_get("@#{name}")).to eq value
      end
    end
  end

  describe '#process' do
    it 'calls #populate with each item of array' do
      allow(subject).to receive(:populate)
      subject.process [item]
      expect(subject).to have_received(:populate).with(item)
    end
  end

  describe '#basic_data_for' do
    it 'assigns related collection basics to @basic_data hash' do
      expect { subject.send(:basic_data_for, related_collection) }
        .to(change { subject.instance_variable_get('@basic_data') }
          .from({}).to(related_collection => related_collection_basics))
    end

    it 'logs warning if collection basics does not exist' do
      with_stubbed_logger do |logger|
        subject.send(:basic_data_for, unexisting_collection)
        expect(logger).to have_received(:warn).with(/#{collection_name}.+basic data.+#{unexisting_collection}/)
      end
    end

    it 'updates basic_data hash with unexisting collection to avoid further lookups' do
      expect { subject.send(:basic_data_for, unexisting_collection) }
        .to(change { subject.instance_variable_get('@basic_data') }.from({}).to(unexisting_collection => {}))
    end
  end

  describe '#searcher_for' do
    it 'returns searcher for collection' do
      expect(subject.send(:searcher_for, related_collection)).to be_a Indago::Searcher
    end

    it 'instantiates searcher with correct collection name' do
      searcher = subject.send(:searcher_for, related_collection)
      expect(searcher.collection_name).to eq related_collection
    end

    it 'stores value in @searchers array to avoid further lookups' do
      searcher = subject.send(:searcher_for, related_collection)
      expect(subject.instance_variable_get('@searchers')).to eq(related_collection => searcher)
    end
  end
end
