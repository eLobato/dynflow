module Eventum
  class Dispatcher
    class << self
      def finalizers
        @finalizers ||= Hash.new { |h, k| h[k] = [] }
      end

      def subscribed_actions(action)
        Action.actions.find_all do |sub_action|
          case sub_action.subscribe
          when Hash
            sub_action.subscribe.keys.include?(action.class)
          when Array
            sub_action.subscribe.include?(action.class)
          else
            sub_action.subscribe == action.class
          end
        end
      end

      def execution_plan_for(action, *plan_args)
        ordered_actions = subscribed_actions(action).sort_by(&:name)

        execution_plan = []
        ordered_actions.each do |action_class|
          execution_plan.concat(action_class.plan(*plan_args))
        end
        return execution_plan
      end
    end
  end
end