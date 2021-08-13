# frozen_string_literal: true
# typed: true

extend T::Sig

class ExceededError < RuntimeError
end

class SegmentExceededError < ExceededError
end

sig {params(handler: Handler).returns(Integer)}
def execute(handler)
  with_deadline(handler, 50.0) do
    begin
      p "inside execute block #{Thread.current[:tlsvalue]}"
      if handler.expired?
        return 10
      end
      raise SegmentExceededError, 'whoops'
    ensure
      p "execute ensure"
    end
  end
end

sig {params(handler: Handler, timeout: Float, blk: T.untyped).returns(T.untyped)}
def with_deadline(handler, timeout, &blk)
  begin
    p "with_deadline/begin"
    api_with_deadline(handler, timeout) {yield}
  ensure
    p "with_deadline/ensure"
  end
end

sig {params(handler: Handler, timeout: Float, blk: T.untyped).returns(T.untyped)}
def api_with_deadline(handler, timeout, &blk)
  p "api_with_deadline enter"
  handler.handler_with_deadline(timeout, &blk)
end

class Timer
  extend T::Sig

  sig {params(timeout: Float, blk: T.untyped).returns(T.untyped)}
  def track_time(timeout, &blk)
    begin
      p "track_time enter"
      yield
    ensure
      p "track_time ensure #{timeout}"
    end
  end
end

Thread.current[:tlsvalue] = :start
p execute(Handler.new(Timer.new))

p Thread.current[:tlsvalue]
