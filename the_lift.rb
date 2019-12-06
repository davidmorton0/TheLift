require "test/unit/assertions"
include Test::Unit::Assertions

class Lift
  attr_accessor :floor
  attr_accessor :passengers
  attr_accessor :direction
  attr_accessor :busy
  attr_reader :capacity
  def initialize(capacity)
    @capacity = capacity
    @floor = 0
    @passengers = []
    @direction = :up
    @busy = true
  end
end

def stop_needed?(floor, queue, passengers)
	#puts "Flr:#{floor}, Q:#{queue}, Pas:#{passengers}, FlrQ:#{queue[floor]}"
	#does lift need to stop at floor?
	if passengers.include?(floor)
		return true
	elsif queue[floor].length > 0
		return true
	else
		return false
	end
end

def stop_at_floor(floor, queue, passengers, capacity)
	#passengers get off
	passengers.delete(floor)
	#space available in lift
	space = capacity - passengers.length
	# passengers get on
	passengers += queue.take(space)
	passengers.sort!
	# remove passengers from queue
	queue = queue.drop(space)
	return [queue, passengers]
end

def direction_queue(direction, queues)
	#works out queues for each direction
	queues.each_with_index.map do |q, i|
		if q.length == 0
			[]
		else
			check_floor = i
			direction == :up ? q.select { | r | r > check_floor } : q.select { | r | r < check_floor }
		end
	end
end

def the_lift(queues, capacity)
  lift = Lift.new(capacity)
  top_floor = queues.length - 1
  result = [0]
  #create up and down queues
  queue = {up: direction_queue(:up, queues), down: direction_queue(:down, queues) }
  #puts "P:#{lift.passengers}, C:#{lift.capacity} Q:#{queues}, UpQ:#{queue[:up]}, DnQ:#{queue[:down]}"
  while lift.busy
  	if stop_needed?(lift.floor, queue[lift.direction], lift.passengers)
  		#puts "Stopping at floor: #{lift.floor}, Going:#{lift.direction}, P:#{lift.passengers}, Busy:#{lift.busy}"
  		#puts "UpQ:#{queue[:up]}, DnQ:#{queue[:down]}"
  		if result[-1] != lift.floor then result.append(lift.floor) end
  		queue[lift.direction][lift.floor], lift.passengers = stop_at_floor(lift.floor,
  					queue[lift.direction][lift.floor], lift.passengers, lift.capacity)
  	else
  		#puts "Missing floor: #{lift.floor}, Going:#{lift.direction}, P:#{lift.passengers}, Busy:#{lift.busy}"
  		#puts "UpQ:#{queue[:up]}, DnQ:#{queue[:down]}"
  	end
  	if lift.floor == 0 and lift.direction == :down
  		lift.direction = :up
  		if lift.passengers.length == 0 and queue[:up].flatten.length == 0 and queue[:down].flatten.length == 0
  			lift.busy = false
  			if result[-1] != lift.floor then result.append(lift.floor) end
  		end
  	elsif lift.floor == top_floor and lift.direction == :up
  		lift.direction = :down
  	elsif lift.direction == :up
  		lift.floor += 1
  	else
  		lift.floor -= 1
  	end
  end
  #puts "#{result}\n\n"
  result
end

#test
#test stop needed
assert_equal stop_needed?(1, [ [], [], [] ] , [1]), true, "passengers need to get off"
assert_equal stop_needed?(1, [ [], [0], [] ] , []), true, "passengers need to get on"
assert_equal stop_needed?(1, [ [1, 1], [], [1, 0] ] , [0, 2]), false, "no stop needed"
assert_equal stop_needed?(2, [ [], [], [] ] , []), false, "no people"
#test up queue
assert_equal direction_queue( :up, [ [1], [0, 2], [0, 1] ] ), [ [1], [2], [] ], "create up queue"
assert_equal direction_queue( :down, [ [1], [0, 2], [0, 1] ] ), [ [], [0], [0, 1] ], "create down queue"
#lift
test_lift = Lift.new(5)
assert_equal test_lift.capacity, 5, "create new lift:capacity"
assert_equal test_lift.direction, :up, "create new lift:direction"
assert_equal test_lift.floor, 0, "create new lift:floor"
assert_equal test_lift.passengers, [], "create new lift:passengers"
#stop at floor
assert_equal stop_at_floor(2, [], [2, 3, 4, 5], 4), [[], [3, 4, 5]] , "passengers get off"
assert_equal stop_at_floor(2, [3], [3, 4, 5], 4), [[], [3, 3, 4, 5]] , "passenger gets on"
assert_equal stop_at_floor(2, [3], [3, 4, 5], 3), [[3], [3, 4, 5]] , "no space in lift"
assert_equal stop_at_floor(2, [3], [5], 5), [[], [3, 5]] , "extra space in lift"
assert_equal stop_at_floor(0, [3, 4, 1, 2, 3, 4], [0, 0, 1, 1], 4), [[1, 2, 3, 4], [1, 1, 3, 4]] , "busy lift"

# full test
#assert_equal the_lift([ [], [], [5,5,5], [], [], [], [] ], 5), [0, 2, 5, 0], "test 1"
assert_equal the_lift([[3], [2], [0], [2], [], [], [5]], 5), [0, 1, 2, 3, 6, 5, 3, 2, 0], "test 2: up and down"


# Floors:    G     1      2        3     4      5      6         Answers:
tests = [[ [ [],   [],    [5,5,5], [],   [],    [],    [] ],     [0, 2, 5, 0]          ],
         [ [ [],   [],    [1,1],   [],   [],    [],    [] ],     [0, 2, 1, 0]          ],
         [ [ [],   [3,],  [4,],    [],   [5,],  [],    [] ],     [0, 1, 2, 3, 4, 5, 0] ],
         [ [ [],   [0,],  [],      [],   [2,],  [3,],  [] ],     [0, 5, 4, 3, 2, 1, 0] ]]
  
for queues, answer in tests do
  Test.assert_equal(the_lift(queues, 5), answer)
end