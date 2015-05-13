# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require 'new_relic/agent/aws_info'

module NewRelic
  module Agent
    class UtilizationData
      def harvest!
        [hostname, container_id, cpu_count, instance_type]
      end

      # No persistent data, so no need for merging or resetting
      def merge!(*_); end
      def reset!(*_); end

      def hostname
        NewRelic::Agent::Hostname.get
      end

      def container_id
        ::NewRelic::Agent::SystemInfo.docker_container_id
      end

      def cpu_count
        ::NewRelic::Agent::SystemInfo.clear_processor_info
        ::NewRelic::Agent::SystemInfo.num_logical_processors
      end

      [:instance_type, :instance_id, :availability_zone].each do |method_name|
        define_method(method_name) do
          load_aws_info unless @aws_info
          @aws_info.send(method_name)
        end
      end

      protected

      def load_aws_info
        @aws_info = AWSInfo.new
        @aws_info.load_remote_data
      end
    end
  end
end
