class Mailbox
  def initialize(socket)
    @socket = socket
  end

  # max amount of data that can be pushed on to a unix socket in a DGRAM packet
  # seems to be around 210000 bytes.  Normally eventmachine only reads 16384
  # chars at a time, but my fork has it reading the max length, so no need to
  # collate, just make sure all packets are under the size limit.
  #
  # max size of dgram packet is around 212000
  def send(message)
    begin
      @socket.sendmsg_nonblock Marshal.dump(message), 0
    rescue IO::EAGAINWaitWritable
      # socket is full
      # TODO put the data into a queue rather than giving up
      raise RuntimeError, "socket is full"
    end
  end

  def receive()
    begin
      raw_data = @socket.recv_nonblock(1000000)
      Marshal.load raw_data
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      # nothing there
      nil
    end
  end
end

