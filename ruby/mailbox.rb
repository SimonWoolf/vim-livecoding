# Wrap streaming socket communication up in a mailbox-like structure
# Main advantage over using DGRAM sockets is that EventMachine helpers
# only support :STREAM sockets, but also the lack of size limit is helpful
class Mailbox
  def initialize(socket)
    @messages = []
    @socket = socket
  end

  def shift
    @messages.shift
  end

  def push
    @messages.push
  end

  # max amount of data that can be pushed on to a unix socket seems to be
  # 219264 bytes.  but -- eventmachine only reads 16384 chars at a time.
  #
  # max size of dgram packet is around 212000
  def send(data)
    check_size data
    @socket.send data, 0
  end

  def receive
    begin
      @socket.recv_nonblock()
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      ""
    end
  end

  private
  def check_size
    if data.length > 219264
      # fail rather than risk bad data
      # TODO: write the data to a file and send a message saying read from the file?
      raise RuntimeError, "maximum message size exceeded"
    end
  end
end

