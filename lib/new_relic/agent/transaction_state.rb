# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require 'new_relic/agent/browser_token'

module NewRelic
  module Agent

    # This is THE location to store thread local information during a transaction
    # Need a new piece of data? Add a method here, NOT a new thread local variable.
    class TransactionState

      def self.get
        self.for(Thread.current)
      end

      def self.for(thread)
        thread[:newrelic_transaction_state] ||= TransactionState.new
      end

      def self.clear
        Thread.current[:newrelic_transaction_state] = nil
      end

      # This starts the timer for the transaction.
      def self.reset(request=nil)
        self.get.reset(request)
      end

      def reset(request)
        @transaction_start_time = Time.now
        @transaction = Transaction.current

        @request = request
        @request_token = BrowserToken.get_token(request)
        @request_guid = ""
        @request_ignore_enduser = false
      end

      # Cross app tracing
      # Because we need values from headers before the transaction actually starts
      attr_accessor :client_cross_app_id, :referring_transaction_info

      # Request data
      attr_accessor :request, :request_token, :request_guid, :request_ignore_enduser

      # Current transaction stack and sample building
      attr_accessor :transaction, :transaction_start_time,
                    :current_transaction_stack, :transaction_sample_builder

      def duration
        Time.now - self.transaction_start_time
      end

      # Execution tracing on current thread
      attr_accessor :untraced

      def push_traced(should_trace)
        @untraced ||= []
        @untraced << should_trace
      end

      def pop_traced
        @untraced.pop if @untraced
      end

      def is_traced?
        @untraced.nil? || @untraced.last != false
      end

      # TT's and SQL
      attr_accessor :record_tt, :record_sql

      def is_transaction_traced?
        @record_tt != false
      end

      def is_sql_recorded?
        @record_sql != false
      end

      # Busy calculator
      attr_accessor :busy_entries

      # Sql Sampler Transaction Data
      attr_accessor :sql_sampler_transaction_data

      # Scope stack and name tracking from NewRelic::StatsEngine::Transactions
      attr_accessor :scope_stack, :scope_name

      def clear_scope_stack_and_name
        @scope_stack = nil
        @scope_name = nil
      end

    end
  end
end