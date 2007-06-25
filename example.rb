Aspects.provide(:logging).with(:logger).using(Logger.new)

Aspects.create(:logging) do
  
  with_class(Purchase).before(:new, :create, :create!) do |class|
    logger.log "a purchase was created"
  end
  
  with_instance(Purchase).after(:save, :save!) do |instance|
    logger.log "a purchase was saved"
  end
  
end