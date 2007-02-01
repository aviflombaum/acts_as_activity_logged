class ActivityLog < ActiveRecord::Base
  belongs_to :activity_loggable, :polymorphic => true
  belongs_to :referenced, :polymorphic => true
  belongs_to :culprit, :polymorphic => true

  alias the_culprit culprit
  def culprit(options="nil")
    options.to_sym == :value ? 
      ((defined? l_klass.models[:culprit] && defined? l_klass.models[:culprit][:method]) ?
        the_culprit.send(l_klass.models[:culprit][:method].to_s) :
        "You must set a :method in the options to use this") : 
      the_culprit
  rescue
    return "anonymous"
  end
  
  alias the_referenced referenced
  def referenced(options="nil")
    options.to_sym == :value ? 
      ((defined? l_klass.models[:referenced] && defined? l_klass.models[:referenced][:method]) ?
        the_referenced.send(l_klass.models[:referenced][:method].to_s) :
        "You must set a :method in the options to use this") :
        the_referenced
  rescue
    return "anonymous"  
  end

  alias the_activity_loggable activity_loggable
  def activity_loggable(options="nil")
    options.to_sym == :value ? 
      ((defined? l_klass.models[:activity_loggable] && defined? l_klass.models[:activity_loggable][:method]) ?
        the_activity_loggable.send(l_klass.models[:activity_loggable][:method].to_s) :
        "You must set a :method in the options to use this") :
        the_activity_loggable
  rescue
    return "anonymous"  
  end
  
  def self.latest(limit=5)
    self.find(:all, :limit => limit)
  end
  
  # options are :culprit, :referenced, :activity_loggable, :limit
  def self.find_with(options={})
    limit = (options.delete(:limit) || 10)
    conditions = self.build_sql_conditional_for(options)
    self.find(:all, :conditions => conditions, :limit => limit)
  # rescue
  #   raise "I couldn't run the find with the options you gave me, sorry"
  end

private
  def decide_conditional(option)
    if option.value.is_a?Array
      "IN"
    else
      "="
    end
  end
  
  def build_sql_conditional_for(options={})
    conditions = []
    options.each do |key, value|
      conditional = decide_conditional(option)
      conditions << self.send(:sanitize_sql, ["#{option.key.to_s}_id #{conditional} ?", option.value])
    end
    return conditions
  end

  def l_klass
    Object.const_get(self.activity_loggable_type.to_s)
  end
  
  def r_klass
    Object.const_get(self.referenced_type.to_s)
  end
  
  def c_klass
    Object.const_get(self.culprit_type.to_s)
  end
end