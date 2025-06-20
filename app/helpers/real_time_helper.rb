# frozen_string_literal: true

module RealTimeHelper
  def real_time_component(id:, url: nil, interval: 0, &)
    content = capture(&) if block_given?
    render "shared/real_time_component", id: id, url: url, interval: interval do |component|
      content
    end
  end

  def real_time_frame(id:, url: nil, interval: 0, title: nil, &)
    content = capture(&) if block_given?
    render "shared/real_time_component", id: id, url: url, interval: interval, title: title, content: content
  end
end
