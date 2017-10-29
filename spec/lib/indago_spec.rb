describe Indago do
  describe '.logger' do
    it 'returns an instance of logger' do
      expect(subject.logger).to be_a Logger
    end

    it 'returns same instance of logger every time it is called' do
      logger_id = subject.logger.object_id
      expect(subject.logger.object_id).to eq logger_id
    end
  end
end
