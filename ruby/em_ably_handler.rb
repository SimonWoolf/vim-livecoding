module EmAblyHandler
  def post_init
    send [:message, "initialized"]
  end

  def receive_data(raw_data)
    begin
      process_message *Marshal.load(raw_data)
    rescue StandardError => e
      send [:error, e]
      EM.next_tick {EM.stop}
    end
  end

  def unbind
    EM.stop
  end

  private

  def send(message)
    send_data Marshal.dump(message)
  end

  def process_message(action, data)
    case action
    when :diff
      send [:message, "received #{data.inspect}"]
    when :close
      send [:message, "Connection closed, all publishing has stopped"]
    end
  end
end

