module Dynflow
  module Connectors
    class Abstract
      include Algebrick::TypeCheck

      def initialize(world)
        @world = world
      end

      def start_listening(world)
        raise NotImplementedError
      end

      def stop_listening(world)
        raise NotImplementedError
      end

      def terminate
        raise NotImplementedError
      end

      def send(receiver, object)
        raise NotImplementedError
      end

      def dump(object)
        MultiJson.dump(object.to_hash)
      end

      def load(string)
        Protocol::Message.from_hash MultiJson.load(string)
      end

    end
  end
end
