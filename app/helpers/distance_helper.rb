module DistanceHelper
  def distance_badge(distance)
    return unless distance
    
    color_class, icon = case distance
    when 0..0.5
      ["green", "🟢"]
    when 0.5..1.0
      ["light-green", "🚶"]
    when 1.0..1.5
      ["yellow", "🚶‍♂️"]
    when 1.5..2.5
      ["orange", "🚲"]
    else
      ["red", "🚗"]
    end
    
    content_tag :span, 
                "#{icon} #{distance} km",
                class: "distance-badge distance-#{color_class}",
                style: "display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; background: #f0f0f0;"
  end
end
