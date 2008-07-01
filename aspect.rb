#
# I had a look at AspectR [1], and it looked awfully confusing.
# I then had a look at AOP on wikipedia [2], I think the people
# who contributed to that have possibly gone whacko. An excerpt:
#
# "Since the risk is to code written by others, code weaving can 
#  be emotional for the authors of the original code. There is 
#  little moral grounding to guide programmers in these matters 
#  because morality isn't something often applied to coding practices"
#
# What??!
#
# Here is my non-academic completely morality-free implementation.
#
# See line 99 for the API. Feedback is appreciated.
#
# Ryan Allen (aspect@yeahnah.org)
#
# [1] http://aspectr.sourceforge.net/
# [2] http://en.wikipedia.org/wiki/Aspect-oriented_programming
#

module Aspect

  class << self

    def define(&aspects)
      instance_eval(&aspects)
    end
  
    def with_instance_of(klass)
      @class = klass
      @subject = :instance
      self
    end
    
    def with_class(klass)
      @class = klass
      @subject = :class
      self
    end
    
    def before(method_name, &perform_before)
      with_scope do
        method_prior = instance_method(method_name)
        define_method method_name do |*args|
          perform_before.call(self, *args)
          method_prior.bind(self).call(*args)
        end
      end
    end
    
    def after(method_name, &perform_after)
      with_scope do
        method_prior = instance_method(method_name)
        define_method method_name do |*args|
          return_value = method_prior.bind(self).call(*args)
          perform_after.call(self, *args)
          return_value
        end
      end
    end
    
    def with_scope(&code)
      if @subject == :class
        @class.class_eval { class << self; self; end }.instance_eval(&code)
      else
        @class.class_eval(&code)
      end
    end

  end
  
end

if __FILE__ == $0
  
  class Client
    
    def self.create
      puts 'Client.create'
      new
    end
    
    def announce(message)
      puts "Client#announce(#{message.inspect})"
    end
    
    def announce_many(*messages)
      messages.each { |message| announce(message) }
    end
    
    def save
      puts 'Client#save'
    end
    
  end
  
  Aspect.define do
    
    with_instance_of(Client).before(:save) do |instance|
      puts "before #{instance.class}#save"
    end
    
    with_instance_of(Client).after(:save) do |instance|
      puts "after #{instance.class}#save"
    end
    
    with_instance_of(Client).before(:announce_many) do |instance, *messages|
      puts "before Client#announce_many(#{messages.inspect})"
    end
    
    with_instance_of(Client).after(:announce) do |instance, message|
      puts "after Client#announce(#{message.inspect})"
    end
    
    with_class(Client).before(:create) do |klass|
      puts "before #{klass}.create"
    end
    
    with_class(Client).after(:create) do |klass|
      puts "after #{klass}.create"
    end
    
  end
  
  client = Client.create
  client.announce('The sky is falling!')
  client.announce_many('Really, it is!', 'I am not joking!!!')
  client.save
  
  # Output should be:
  # before Client.create
  # Client.create
  # after Client.create
  # Client#announce("The sky is falling!")
  # after Client#announce("The sky is falling!")
  # before Client#announce_many(["Really, it is!", "I am not joking!!!"])
  # Client#announce("Really, it is!")
  # after Client#announce("Really, it is!")
  # Client#announce("I am not joking!!!")
  # after Client#announce("I am not joking!!!")
  # before Client#save
  # Client#save
  # after Client#save
  
end
