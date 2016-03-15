WINNING_COMBOS = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [1, 4, 7],
                  [2, 5, 8], [3, 6, 9], [1, 5, 9], [3, 5, 7]]

DISPLAY_TEMPLATE = { x: ['   .   .   ', '    \ /    ', '     /     ', '    / \    ', '   .   .   '],
                     o: ['   .--.    ', '  :    :   ', '  |    |   ', '  :    ;   ', '   `--\'    '],
                     blank: [' ' * 11, ' ' * 11, ' ' * 11, ' ' * 11, ' ' * 11] }
PLAYER_MARKER = :x
COMPUTER_MARKER = :o


def prompt(message)
  puts "=> " + message
end

def select_difficulty
  prompt "Please select your difficulty (easy/hard)"
  loop do 
    difficulty = gets.chomp.downcase
    return difficulty if ["easy", "hard"].include?(difficulty)
    prompt "That is not a valid selection.\nPlease re-enter your difficulty. (easy/hard)"
  end
end

def initialize_board
  board = {}
  (1..9).each {|position| board[position] = :blank}
  board
end

def update_screen(current_board, loc)
  system 'clear' or system 'cls'
  update_board(current_board)
  update_prompt(loc)
end

def update_board(current_board)
  spacer = ' ' * 4
  puts
  (1..9).step(3) do |square_num|
    for col in 0..4
      puts "#{spacer}#{DISPLAY_TEMPLATE[current_board[square_num]][col]}|"\
           "#{DISPLAY_TEMPLATE[current_board[square_num + 1]][col]}|"\
           "#{DISPLAY_TEMPLATE[current_board[square_num + 2]][col]}"
    end
    puts "#{spacer}-----------+-----------+-----------" unless square_num > 4
  end
end

def update_prompt(loc)
  spacer = ' ' * 16
  puts
  prompt("Select an available location between 1 and 9")
  puts format("\n%s %s | %s | %s\n"\
                "%s---+---+---\n"\
                "%s %s | %s | %s\n"\
                "%s---+---+---\n"\
                "%s %s | %s | %s\n",
                spacer, loc[0], loc[1], loc[2],
                spacer,
                spacer, loc[3], loc[4], loc[5],
                spacer,
                spacer, loc[6], loc[7], loc[8])
end

def user_select_square(current_board, square_index)
  loop do
    user_spot = gets.chomp

    if square_index.include?(user_spot)
      return user_spot.to_i
    else
      update_screen(current_board, square_index)
      puts
      prompt(user_error_message(user_spot))
    end
  end
end

def user_error_message(user_spot)
  if (1..9).include?(user_spot.to_i)
    "That square has been taken. Please select another square"
  else
    "That is not a valid selection. Please select a number between 1 and 9."
  end
end

def update_board_and_index(current_board, square_index, selection, player_marker)
  current_board[selection] = player_marker
  square_index[selection - 1] = " "
  return current_board, square_index
end

def check_winner(current_board, player_marker)
  player_numbers = current_board.select { |num, sq| sq == player_marker }
  return WINNING_COMBOS.any? do |combo|
    combo.all? { |combo_num| player_numbers.include?(combo_num) }
  end
end

def advanced_computer_spot_selection(current_board)
  user_numbers = current_board.select { |num, sq| sq == PLAYER_MARKER }.keys
  computer_numbers = current_board.select { |num, sq| sq == COMPUTER_MARKER }.keys
  computer_spot = find_critical_square(computer_numbers, user_numbers)
  computer_spot ||= find_critical_square(user_numbers, computer_numbers)
  computer_spot ||= find_best_square(user_numbers, computer_numbers)
  computer_spot ||= 5 if current_board[5] == :blank
  computer_spot
end

def find_critical_square(p1_numbers, p2_numbers)
  WINNING_COMBOS.each do |combo|
    squares_in_combo = 0
    critical_square = nil
    critical_square, squares_in_combo =
      check_square_in_combo(combo, p1_numbers, p2_numbers, squares_in_combo, critical_square)
    return critical_square if critical_square && squares_in_combo == 2
  end
  nil
end

def check_square_in_combo(combo, p1_numbers, p2_numbers, squares_in_combo, critical_square)
  combo.each do |sq|
    if p1_numbers.include?(sq)
      squares_in_combo += 1
    else
      critical_square = sq unless p2_numbers.include?(sq)
    end
  end
  return critical_square, squares_in_combo
end

def find_best_square(user_numbers, computer_numbers)
  user_possible_winning_combos = find_possible_winning_combos(user_numbers, computer_numbers)
  computer_possible_winning_combos = find_possible_winning_combos(computer_numbers, user_numbers)
  fork_opportunities = find_fork_opportunities(user_possible_winning_combos, user_numbers)
  
  if fork_opportunities.length == 2
    select_best_computer_square(computer_possible_winning_combos, computer_numbers, fork_opportunities)
  elsif fork_opportunities.length > 1
    fork_opportunities.select { |fork_sq| computer_possible_winning_combos.flatten.include?(fork_sq) }.sample
  else
    fork_opportunities[0]
  end
end

def select_best_computer_square(computer_possible_winning_combos, computer_numbers, fork_opportunities)
  computer_possible_winning_combos.flatten.select do |combo_sq|
    !(computer_numbers + fork_opportunities).include?(combo_sq)
  end.sample
end

def find_possible_winning_combos(p1_numbers, p2_numbers)
  p1_winning_combos = WINNING_COMBOS.select do |combo|
    combo.all? { |sq| !p2_numbers.include?(sq) } && combo.any? { |sq| p1_numbers.include?(sq) }
  end
end

def find_fork_opportunities(user_possible_winning_combos, user_numbers)
  fork_opportunities = []
  user_possible_winning_combos.each do |combo|
    combo.each do |num|
      intersecting_combos = find_intersecting_combos(num, user_possible_winning_combos, user_numbers)
      if intersecting_combos > 1
        fork_opportunities << num unless fork_opportunities.include?(num)
      end
    end
  end
  fork_opportunities
end

def find_intersecting_combos(num, user_possible_winning_combos, user_numbers)
  intersecting_combos = 0
  user_possible_winning_combos.each do |user_possible_winning_combo|
    intersecting_combos += 1 if user_possible_winning_combo.include?(num) && !user_numbers.include?(num)
  end
  intersecting_combos
end

def display_winner_message(winner, difficulty)
  puts
  sleep 1
  case winner
  when :user then congratulate_winner
  when :computer then ridicule_loss
  else comment_on_tie(difficulty)
  end
  sleep 1
end

def congratulate_winner
  prompt("Congratulations! You won!")
  sleep 1
  prompt("On easy...\n\n")
end

def ridicule_loss
  prompt("You lost at tic-tac-toe... that's embarrasing.\n\n")
end

def comment_on_tie(difficulty)
  prompt("Tied. Try it on easy if you feel like winning...\n\n")
  if difficulty == "easy"
    sleep 1
    prompt("Oh wait... you are on easy... ouch\n\n")
  end 
end


# Initialize board and select difficulty
system 'clear' or system 'cls'
difficulty = select_difficulty
current_board = initialize_board
square_index = %w(1 2 3 4 5 6 7 8 9)
winner = nil
update_screen(current_board, square_index)


loop do # MAIN LOOP
  user_selection = user_select_square(current_board, square_index)
  current_board, square_index = update_board_and_index(current_board, square_index,
                                                       user_selection, PLAYER_MARKER)

  update_screen(current_board, square_index)
  
  winner = :user if check_winner(current_board, PLAYER_MARKER)
  break if winner
  break if current_board.select {|num, sq| sq == :blank}.empty?

  computer_selection = difficulty == "hard" ? advanced_computer_spot_selection(current_board) : nil
  computer_selection ||= square_index.select { |sq| sq != ' ' }.sample.to_i
  current_board, square_index = update_board_and_index(current_board, square_index,
                                                       computer_selection, COMPUTER_MARKER)
  
  sleep 1
  update_screen(current_board, square_index)

  winner = :computer if check_winner(current_board, COMPUTER_MARKER)
  break if winner
end

display_winner_message(winner, difficulty)
