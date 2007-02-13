# Copyright (c) 2006 New Bamboo
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module NewBamboo #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you want changes to your model to be saved in an
    # activity_logs table.
    #
    #   class Post < ActiveRecord::Base
    #     acts_as_activity_logged
    #   end
    module ActivityLogged #:nodoc:
      CALLBACKS = [:activity_log_create, :activity_log_update, :activity_log_destroy]

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # == Configuration options
        #
        # * <tt>delay_after_create</tt> - No logging on a model until X time afterwords
        #   
        #   e.g. acts_as_activity_loggable :delay_after_create => 15.seconds
        #   
        # * <tt>:models => :culprit</tt> - Activity Log calls this method to determine who did the activity.
        # * <tt>:models => :referenced</tt> - Activity Log calls this method to determine what the activity was done on.
        #   
        #   e.g. acts_as_activity_loggable :models => { :culprit => { :method => :name }
        #
        # - culprit: The object that did the activity
        # - referenced: The object that the activity was done to
        #
        # 
        def acts_as_activity_logged(options = {})
          # don't allow multiple calls
          return if self.included_modules.include?(NewBamboo::Acts::ActivityLogged::InstanceMethods)

          include NewBamboo::Acts::ActivityLogged::InstanceMethods
          
          
          
          class_eval do
            extend NewBamboo::Acts::ActivityLogged::SingletonMethods
            has_many :activity_logs, :as => :activity_loggable
            
            # Logging delay after a create
            cattr_accessor :delay_after_create            
            self.delay_after_create = options.delete(:delay_after_create)
            self.delay_after_create = 0.seconds if self.delay_after_create.nil?
            
            cattr_accessor :models
            self.models = {}
            self.models = options.delete(:models)
            
            cattr_accessor :userstamp
            self.userstamp = options.delete(:timestamp)
                        
            after_create :activity_log_create
            after_update :activity_log_update
            after_destroy :activity_log_destroy
          end
        end
      end
    
      module InstanceMethods
        attr_accessor :skip_log
        
        private        
        # Creates a new record in the activity_logs table if applicable
        def activity_log_create
          write_activity_log(:create)
        end

        def activity_log_update
          write_activity_log(:update)
        end

        def activity_log_destroy
          write_activity_log(:destroy)
        end
        
        # This writes the activity log, but if the :delay_after_create option is set, it will only write
        # the log if the time given by :delay_after_create has passed since the object was created. If
        # the object does not have a created_at attribute this switch will be ignored
        def write_activity_log(action = :update)
          set_culprit
          set_referenced
          if (self.respond_to?(:created_at) && Time.now > self.delay_after_create.since(self.created_at)) || action == :create
            r = self.activity_logs.create :action => action.to_s, 
                                          :referenced => @referenced,
                                          :culprit => @culprit unless @skip_log == true
          end
          @skip_log = false
          return true
        end

        # If the userstamp option is given, call User.current_user(supplied by the userstamp plugin) 
        # otherwise use the models user method.
        # http://delynnberry.com/projects/userstamp/
        def set_culprit
          @culprit ||= (self.userstamp ? User.current_user : self.send(models[:culprit][:model].to_s)) if 
                                                                          !models.nil? &&
                                                                          models.has_key?(:culprit) && 
                                                                          models[:culprit].has_key?(:model)
        end
        
        def set_referenced
          @referenced ||= self.send(models[:referenced][:model].to_s) if !models.nil? &&
                                                                          models.has_key?(:referenced) && 
                                                                          models[:referenced].has_key?(:model)
        end

        # Alias any existing callback methods
        CALLBACKS.each do |attr_name| 
          alias_method "orig_#{attr_name}".to_sym, attr_name
        end
        
        def empty_callback() end #:nodoc:

      end # InstanceMethods
      
      module SingletonMethods

      end
    end
  end
end