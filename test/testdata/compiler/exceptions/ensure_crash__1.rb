# frozen_string_literal: true
# typed: true
# compiled: true

class Handler
  extend T::Sig

  def initialize(timer)
    @timer = T.let(timer, Timer)
  end

  sig {params(timeout: Float, blk: T.untyped).returns(T.untyped)}
  def with_override(timeout, &blk)
    t = Thread.current[:tlsvalue]
    p "tlsvalue #{t}"
    begin
      Thread.current[:tlsvalue] = :inside_override
      yield
    ensure
      Thread.current[:tlsvalue] = t
    end
  end

  sig {params(timeout: Float, blk: T.untyped).returns(T.untyped)}
  def handler_with_deadline(timeout, &blk)
    with_override(timeout) do
      trapped = T.let(false, T::Boolean)
      begin
        p "handler_with_deadline enter"
        v = 1
        unless trapped
          v = if timeout < 10.0
            yield
          elsif timeout < 20.0
            yield
          else
            @timer.track_time(timeout, &blk)
          end
        end
        if trapped
          1800
        else
          v
        end
      rescue SegmentExceededError => e
        p "running exception handler"
        trapped = true
        raise e
      end
    end
  end

  sig {returns(T::Boolean)}
  def expired?
    true
  end
end

require_relative 'ensure_crash__2.rb'
