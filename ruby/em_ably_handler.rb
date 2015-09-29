module EmAblyHandler
  def post_init
    sendmsg [:message, "initialized"]
  end

  def receive_data(raw_data)
    begin
      process_message *Marshal.load(raw_data)
    rescue StandardError => e
      sendmsg [:error, e]
      EM.next_tick { EM.stop }
    end
  end

  def unbind
    EM.stop
  end

  private

  def sendmsg(message)
    send_data Marshal.dump(message)
  end

  def process_message(action, data)
    case action
    when :diff
      sendmsg [:message, "received #{data.inspect}"]
    when :close
      sendmsg [:message, "Connection closed, all publishing has stopped"]
    end
  end
end

