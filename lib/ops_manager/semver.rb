class OpsManager
  class Semver < Array
    def initialize s
      return unless s
      super(s.split('.').map { |e| e.to_i })
    end

    def < x
      (self <=> x) < 0
    end

    def > x
      (self <=> x) > 0
    end

    def == x
      (self <=> x) == 0
    end

    def to_s
      self.join('.')
    end
  end
end
