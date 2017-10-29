module IndagoSpecHelper
  def with_stubbed_logger
    logger_spy = spy('Indago.logger')
    allow(Indago).to receive(:logger).and_return(logger_spy)
    yield logger_spy
  end

  def read_fixture_file(name)
    File.open(WITHIN_TEST_DIR.call(['fixtures', name]), &:read)
  end
end
