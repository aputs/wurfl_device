require 'redis'

class Redis
  module Lock
    class LockTimeout < StandardError; end

    def lock_for(key, expires=60, timeout=10)
      if self.lock(key, expires, timeout)
        response = yield(self) if block_given?
        self.unlock(key)
        return response
      end
    end

    def lock(key, expires, timeout)
      while timeout >= 0
        expiry_time = Time.now.to_i + expires + 1
        return true if setnx(key, expiry_time)
        current_value = get(key).to_i
        sleep(2)
        return true if current_value && current_value < Time.now.to_i && getset(key, expiry_time).to_i == current_value
        timeout -= 1
      end
      raise LockTimeout, 'Timeout whilst waiting for lock'
    end

    def extend_lock(key, expires)
      expiry_time = Time.now.to_i + expires + 1
      set(key, expiry_time)
    end

    def unlock(key)
      del(key)
    end
  end

  include Lock
end