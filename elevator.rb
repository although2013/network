require 'set'

class PeoplePool
  attr_accessor :mutex

  def initialize
    @pool = {
      f1: {
        up: [5,5,6,7,8,9,10,11,15,15,11,8,17],
      },
      f4: {
        up: [12, 12],
        down: nil,
      },
      f11: {
        up: [17],
        down: [1, 2],
      }
    }
    @mutex = Mutex.new
  end

  def pool
    @pool
  end

  def shift(floor, updown, count)
    waiting = @pool["f#{floor}".to_sym]&.[](updown)
    if waiting
      waiting.shift(count)
    else
      []
    end
  end
end


class Elevator
  def initialize(id)
    @max_quantity = 6
    @id = id
    @current_floor = 1
    @current_action = nil
    @people = []
  end

  def running
    loop do
      if @people.empty?
        target_floor, action = get_target_from_controller
        if target_floor
          run_to_a_target(target_floor, action)
        else
          sleep(0.5)
        end
      else
        run_to_a_target
      end
    end
  end

  def target_floors_in_elevator
    @people.sort.uniq
  end

  def get_target_from_controller
    $people_pool.mutex.synchronize do
      $people_pool.pool.keys.each do |floor|
        if $people_pool.pool[floor]&.[](:up)&.any?
          return floor.to_s[1..-1].to_i, :up
        elsif $people_pool.pool[floor]&.[](:down)&.any?
          return floor.to_s[1..-1].to_i, :down
        end
      end
      p $people_pool.pool
      return nil, nil
    end
  end

  def moving_to_target_floor(out_target_floor, action)
    if out_target_floor
      @current_floor = out_target_floor
      @current_action = action
    else
      @current_floor = case @current_action
                      when :up
                        target_floors_in_elevator.first
                      when :down
                        target_floors_in_elevator.last
                      end
    end
    puts "#{@id}: floor #{@current_floor}, #{@current_action}"
    sleep(1) 
  end

  def out_people
    outing = @people.select { |p| p == @current_floor }
    puts "#{@id}: out people #{outing}"
    outing.each do |person|
      sleep(0.2)
    end
    @people = @people.select { |p| p != @current_floor }
  end

  def in_people
    can_in_count = @max_quantity - @people.count
    # TODO
    # @people << PeoplePool.pool[@current_floor][@current_action]
              # .pop(can_in_count)
    $people_pool.mutex.synchronize do
      @people.push(*$people_pool.shift(@current_floor, @current_action, can_in_count))
    end
    puts "#{@id}: Elevator people: #{@people}"
  end

  def run_to_a_target(out_target_floor=nil, action=nil)
    moving_to_target_floor(out_target_floor, action)
    out_people
    in_people
  end
end



$people_pool = PeoplePool.new


threads = (1..5).map do |i|
  elevator = Elevator.new(i)
  Thread.new do
  #   $people_pool.mutex.synchronize do
      elevator.running
  #   end
  end
end

threads.each(&:join)