require_relative 'spec_helper'
require 'simple_command'

describe "Command" do
  
  describe "SimpleCommand" do
    it "should allow valid in put in" do
      outcome = SimpleCommand.run(name: "John", email: "john@gmail.com", amount: 5)

      assert outcome.success?
      assert_equal ({name: "John", email: "john@gmail.com", amount: 5}).stringify_keys, outcome.result
      assert_equal nil, outcome.errors
    end
    
    it "should filter out spurious params" do
      outcome = SimpleCommand.run(name: "John", email: "john@gmail.com", amount: 5, buggers: true)
      
      assert outcome.success?
      assert_equal ({name: "John", email: "john@gmail.com", amount: 5}).stringify_keys, outcome.result
      assert_equal nil, outcome.errors
    end
    
    it "should discover errors in inputs" do
      outcome = SimpleCommand.run(name: "JohnTooLong", email: "john@gmail.com")
      
      assert !outcome.success?
      assert :length, outcome.errors.symbolic[:name]
    end
    
    it "shouldn't throw an exception with run!" do
      result = SimpleCommand.run!(name: "John", email: "john@gmail.com", amount: 5)
      assert_equal ({name: "John", email: "john@gmail.com", amount: 5}).stringify_keys, result
    end
    
    it "should throw an exception with run!" do
      assert_raises Mutations::ValidationException do
        result = SimpleCommand.run!(name: "John", email: "john@gmail.com", amount: "bob")
      end
    end
    
    it "should merge multiple hashes" do
      outcome = SimpleCommand.run({name: "John", email: "john@gmail.com"}, {email: "bob@jones.com", amount: 5})
      
      assert outcome.success?
      assert_equal ({name: "John", email: "bob@jones.com", amount: 5}).stringify_keys, outcome.result
    end
    
    it "should merge hashes indifferently" do
      outcome = SimpleCommand.run({name: "John", email: "john@gmail.com"}, {"email" => "bob@jones.com", "amount" => 5})
      
      assert outcome.success?
      assert_equal ({name: "John", email: "bob@jones.com", amount: 5}).stringify_keys, outcome.result
    end
    
    it "shouldn't accept non-hashes" do
      assert_raises ArgumentError do
        outcome = SimpleCommand.run(nil)
      end
      
      assert_raises ArgumentError do
        outcome = SimpleCommand.run(1)
      end
    end
    
    it "should accept nothing at all" do
      SimpleCommand.run # make sure nothing is raised
    end
  end
  
  describe "EigenCommand" do
    class EigenCommand < Mutations::Command
  
      required { string :name }
      optional { string :email }
  
      def execute
        {name: name, email: email}
      end
    end
  
    it "should define getter methods on params" do
      mutation = EigenCommand.run(name: "John", email: "john@gmail.com")
      assert_equal ({name: "John", email: "john@gmail.com"}), mutation.result
    end
  end
  
  describe "MutatatedCommand" do
    class MutatatedCommand < Mutations::Command
  
      required { string :name }
      optional { string :email }
  
      def execute
        self.name, self.email = "bob", "bob@jones.com"
        {name: inputs[:name], email: inputs[:email]}
      end
    end
  
    it "should define setter methods on params" do
      mutation = MutatatedCommand.run(name: "John", email: "john@gmail.com")
      assert_equal ({name: "bob", email: "bob@jones.com"}), mutation.result
    end
  end
  
  describe "ErrorfulCommand" do
    class ErrorfulCommand < Mutations::Command
  
      required { string :name }
      optional { string :email }
  
      def execute
        add_error("bob", :is_a_bob)
        
        1
      end
    end
  
    it "should let you add errors" do
      outcome = ErrorfulCommand.run(name: "John", email: "john@gmail.com")
      
      assert !outcome.success?
      assert_nil outcome.result
      assert :is_a_bob, outcome.errors.symbolic[:bob]
    end
  end
  
  # TODO: test _present, add_error, merge_errors
end