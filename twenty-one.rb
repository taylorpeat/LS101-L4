CARD_FORMAT = [" _________ ",
               "|%{num}%{n10}%{c8}   %{c8}  |",
               "|%{suit} %{c6} %{c10} %{c6}  |",
               "|  %{c4} %{c7} %{c4}  |",
               "|  %{c6} %{c9} %{c6}  |",
               "|  %{c4} %{c2} %{c4}  |",
               "|  %{c6} %{c10} %{c6} %{suit}|",
               "|  %{c8}   %{c8}%{n10}%{num}|",
               " --------- "].freeze

SUITS = %i(spades clubs hearts diamonds).freeze
VALUES = [["2", 2], ["3", 3], ["4", 4],
          ["5", 5], ["6", 6], ["7", 7],
          ["8", 8], ["9", 9], ["10", 10],
          ["jack", 10], ["queen", 10], ["king", 10], ["ace", 11]].freeze
HAND_LIMIT = 21

def initialize_deck
  deck = SUITS.product(VALUES).map(&:flatten!)
  deck.shuffle!
end

def initialize_variables
  player_total = player_total2 = dealer_total = bet = bet2 = 0
  player_cards = player_cards2 = dealer_cards = []
  stand = stand2 = continue = false
  deck = initialize_deck
  [deck, player_cards, player_cards2, dealer_cards, player_total, player_total2,
   dealer_total, bet, bet2, stand, stand2, continue]
end

def prompt_user_name
  system 'clear' or system 'cls'
  puts "Welcome to Launch School Blackjack"
  print "\nPlease enter your name: "
  name = gets.chomp.capitalize
  loop do
    return name if name != ''
    puts "Name may not be blank."
    name = gets.chomp.capitalize
  end
end

def intro(name)
  puts "\n#{name}, your starting balance is $100."
  puts "\nPress ENTER to begin playing."
  gets
end

def update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                   player_total2, dealer_total, stand, stand2, bet, bet2)
  dealer_total, dealer_cards = dealer_visible_cards(stand, stand2, player_total, player_total2,
                                                    dealer_total, dealer_cards)
  system 'clear' or system 'cls'
  display_top_line(balance, bet, bet2)
  display_cards(player_cards, dealer_cards)
  display_bottom_information(player_cards, player_total, dealer_total)
  display_cards(player_cards2, []) unless player_cards2.empty?
  puts "Second hand total: #{player_total2}" if player_total2 > 0
  puts
end

def dealer_visible_cards(stand, stand2, player_total, player_total2, dealer_total, dealer_cards)
  if stand && (stand2 || player_total2 == 0) && !player_doesnt_care?(player_total, player_total2)
    sleep 1
  else
    dealer_total = dealer_cards[0][2] unless dealer_cards.empty?
    dealer_cards =  dealer_cards.take(1) unless dealer_cards.empty?
  end
  [dealer_total, dealer_cards]
end

def display_top_line(balance, bet, bet2)
  puts "Balance: $#{balance}" + " " * 10 + "--LAUNCH SCHOOL BLACKJACK--"
  puts "Wager:   $#{bet + bet2}"
  puts "\nPlayer Cards:" + " " * 25 + "Dealer Cards:"
end

def display_cards(player_cards, dealer_cards)
  lines = ["", "", "", "", "", "", "", "", ""]
  lines = updated_lines(lines, player_cards)
  lines.each { |line| line << " " * (16 - ((player_cards.length - 2) * 3)) }
  lines.each { |line| line << " " * 8 } if player_cards.length == 1
  lines = updated_lines(lines, dealer_cards)
  lines.each { |line| puts line }
end

def updated_lines(lines, hand)
  hand.each_with_index do |card, idx|
    card_values = update_card_values(card)
    if idx < hand.size - 2
      lines = compile_lines_hidden(lines, card_values)
    else
      lines = compile_lines(lines, card_values)
    end
  end
  lines
end

def display_bottom_information(player_cards, player_total, dealer_total)
  print player_cards.empty? ? "" : "Player total:#{player_total}"
  print player_total < 10 ? " " * 24 : " " * 23
  puts "Dealer total:#{dealer_total}"
end

def update_card_values(card)
  c2, c4, c6, c7, c8, c9, c10, n10 = nil
  num = card[1]
  suit = determine_suit_code(card[0])
  c2, c4, c6, c7, c8, c9, c10, n10 = update_numcard_values(num, suit)
  num, c9 = update_facecard_values(num, suit)
  c2, c4, c6, c7, c8, c9, c10, n10 = [c2, c4, c6, c7, c8, c9, c10, n10].map { |x| x ||= " " }
  [suit, num, c2, c4, c6, c7, c8, c9, c10, n10]
end

def determine_suit_code(suit)
  case suit
  when :spades then suit_code = "\u2660"
  when :clubs then suit_code = "\u2663"
  when :hearts then suit_code = "\u2665"
  when :diamonds then suit_code = "\u2666"
  end
  suit_code
end

def update_numcard_values(num, suit)
  case num
  when "2" then c2 = c7 = suit
  when "3" then c9 = c10 = suit
  when "4" then c4 = suit
  when "5" then c4 = c9 = suit
  when "6" then c6 = suit
  when "7" then c6 = c7 = suit
  when "8" then c4 = c8 = suit
  when "9" then c4 = c8 = c9 = suit
  when "10"
    c4 = c8 = c10 = suit
    n10 = ""
  end
  [c2, c4, c6, c7, c8, c9, c10, n10]
end

def update_facecard_values(num, suit)
  c9 = suit
  case num
  when "ace" then num = "A"
  when "king" then num = "K"
  when "queen" then num = "Q"
  when "jack" then num = "J"
  else c9 = nil
  end
  [num, c9]
end

def compile_lines(lines, cv)
  lines[0] += CARD_FORMAT[0]
  lines[1] += format(CARD_FORMAT[1], num: cv[1], c8: cv[6], n10: cv[9])
  lines[2] += format(CARD_FORMAT[2], suit: cv[0], c6: cv[4], c10: cv[8])
  lines[3] += format(CARD_FORMAT[3], c4: cv[3], c7: cv[5])
  lines[4] += format(CARD_FORMAT[4], c6: cv[4], c9: cv[7])
  lines[5] += format(CARD_FORMAT[5], c2: cv[2], c4: cv[3])
  lines[6] += format(CARD_FORMAT[6], suit: cv[0], c6: cv[4], c10: cv[8])
  lines[7] += format(CARD_FORMAT[7], num: cv[1], c8: cv[6], n10: cv[9])
  lines[8] += CARD_FORMAT[8]
  lines
end

def compile_lines_hidden(lines, cv)
  lines[0] += CARD_FORMAT[0].slice(0..2)
  lines[1] += format(CARD_FORMAT[1], num: cv[1], c8: cv[6], n10: cv[9]).slice(0..2)
  lines[2] += format(CARD_FORMAT[2], suit: cv[0], c6: cv[4], c10: cv[8]).slice(0..2)
  lines[3] += format(CARD_FORMAT[3], c4: cv[3], c7: cv[5]).slice(0..2)
  lines[4] += format(CARD_FORMAT[4], c6: cv[4], c9: cv[7]).slice(0..2)
  lines[5] += format(CARD_FORMAT[5], c2: cv[2], c4: cv[3]).slice(0..2)
  lines[6] += format(CARD_FORMAT[6], suit: cv[0], c6: cv[4], c10: cv[8]).slice(0..2)
  lines[7] += format(CARD_FORMAT[7], num: cv[1], c8: cv[6], n10: cv[9]).slice(0..2)
  lines[8] += CARD_FORMAT[8].slice(0..2)
  lines
end

def initial_prompt(balance)
  system 'clear' or system 'cls'
  puts "Balance: $#{balance}" + " " * 9 + "--TEALEAF BLACKJACK--"
  print "\nHow much would you like to wager: "
  bet = gets.chomp.to_i
  loop do
    break if (1..balance.to_i).cover?(bet)
    display_bet_error_message(bet, balance)
    bet = gets.chomp.to_i
  end
  [bet, balance -= bet]
end

def display_bet_error_message(bet, balance)
  if bet > balance
    print "Your wager exceeds your balance. Please re-enter a valid wager: "
  else
    print "Please re-enter a valid wager: "
  end
end

def determine_plays(player_cards, player_total2, balance, bet)
  valid_plays = %w(Hit Stand)
  if player_total2 == 0
    valid_plays << "Split" if player_cards.length == 2 &&
                              (player_cards[0][2] == player_cards[1][2] ||
                              player_cards[0][1] == player_cards[1][1]) && balance > bet
    valid_plays << "Double" if player_cards.length == 2 && balance > bet
  end
  valid_plays
end

def deal_cards(deck)
  player_cards = [deck[0], deck[2]]
  dealer_cards = [deck[1], deck[3]]
  deck.shift(4)
  player_cards, player_total = determine_hand_values(player_cards)
  dealer_cards, dealer_total = determine_hand_values(dealer_cards)
  [player_cards, dealer_cards, player_total, dealer_total]
end

def determine_hand_values(cards)
  total = cards[0][2] + cards[1][2]
  if total == 22
    total = 12
    cards[1][2] = 1
  end
  [cards, total]
end

def update_hand(deck, balance, player_cards, player_cards2, player_total,
                player_total2, bet, bet2, stand)
  play = prompt_user(player_cards, player_total2, balance, bet)
  case play
  when "Hit" then deck, player_cards, player_total = hit(deck, player_cards, player_total)
  when "Double"
    balance, bet, deck, player_cards, player_total =
      double(balance, bet, deck, player_cards, player_total)
    stand = true
  when "Split"
    balance, bet2, player_cards, player_cards2, player_total, player_total2 =
      split(balance, bet, player_cards, player_cards2)
  when "Stand" then stand = true
  end
  [deck, player_cards, player_cards2, player_total, player_total2, balance, bet, bet2, stand]
end

def double(balance, bet, deck, player_cards, player_total)
  balance -= bet
  bet *= 2
  deck, player_cards, player_total = hit(deck, player_cards, player_total)
  [balance, bet, deck, player_cards, player_total]
end

def split(balance, bet, player_cards, player_cards2)
  balance -= bet
  bet2 = bet
  player_cards2[0] = player_cards[1]
  player_cards = [player_cards[0]]
  player_total = player_cards[0][2]
  player_total2 = player_cards2[0][2]
  [balance, bet2, player_cards, player_cards2, player_total, player_total2]
end

def prompt_user(player_cards, player_cards2, balance, bet)
  valid_plays = determine_plays(player_cards, player_cards2, balance, bet)
  print "\nPlease select an option: "
  valid_plays.each { |play| print play + " " }
  puts
  play = gets.chomp
  loop do
    break if valid_plays.include?(play.capitalize)
    print "\nThat is not a valid option. Please re-enter your selection: "
    play = gets.chomp
  end
  play.capitalize
end

def hit(deck, player_cards, player_total)
  player_cards << deck[0]
  player_cards, player_total = calculate_total(player_cards, player_total)
  deck.shift
  [deck, player_cards, player_total]
end

def calculate_total(player_cards, player_total)
  player_total += player_cards.last[2]
  if player_total > HAND_LIMIT
    if player_cards.any? { |card| card[2] == 11 }
      player_total -= 10
      player_cards.find { |card| card[2] == 11 }[2] = 1
    end
  end
  [player_cards, player_total]
end

def winning_message(player_total, player_total2, dealer_total, bet, bet2, balance, name)
  bet, bonus = decide_winner(player_total, player_total2, dealer_total, bet, name, "first")
  unless player_total2 == 0
    sleep 1
    puts
    bet2, bonus2 = decide_winner(player_total2, 1, dealer_total, bet2, name, "second")
  end
  bonus ||= 0
  bonus2 ||= 0
  balance += (bet * 2 + bet2 * 2 + bonus + bonus2).to_i
  puts "\nYour new balance is $#{balance}."
  balance
end

def decide_winner(player_total, player_total2, dealer_total, bet, name, hand_num)
  if dealer_total == HAND_LIMIT && player_total != HAND_LIMIT || player_total > HAND_LIMIT ||
     player_total < dealer_total && dealer_total <= HAND_LIMIT
    message = loser_message(player_total, dealer_total)
    winnings = bet
    bet = bonus = 0
    result = "lost"
  elsif player_total == dealer_total
    message = "It's a push. You tied the dealer with #{player_total}"
    winnings = 0
    bet /= 2
    result = "tied"
  else
    message, bonus = winner_message(player_total, dealer_total, name, bet)
    winnings = bet + bonus
    result = "won"
  end
  display_result_message(message, player_total2, hand_num, winnings, result)
  [bet, bonus]
end

def loser_message(player_total, dealer_total)
  if dealer_total == HAND_LIMIT
    message = "The dealer hit blackjack"
  elsif player_total > HAND_LIMIT
    message = "You busted"
  elsif player_total < dealer_total && dealer_total <= HAND_LIMIT
    message = "Sorry. You lost to the dealer #{dealer_total} to #{player_total}"
  end
end

def winner_message(player_total, dealer_total, name, bet)
  if player_total == HAND_LIMIT
    message = "Congratulations #{name}! You hit blackjack"
    bonus = bet / 2
  elsif player_total > dealer_total
    message = "Congratulations #{name}! You beat the dealer #{player_total} to #{dealer_total}"
  elsif dealer_total > HAND_LIMIT
    message = "The dealer busted"
  end
  [message, bonus ||= 0]
end

def display_result_message(message, player_total2, hand_num, winnings, result)
  print message
  puts player_total2 == 0 ? "." : " on your #{hand_num} hand."
  puts "You #{result} $#{winnings}." unless result == "tied"
end

def player_doesnt_care?(player_total, player_total2)
  player_total >= HAND_LIMIT && (player_total2 == 0 || player_total2 >= HAND_LIMIT)
end

def prompt_continue?(name)
  puts "\n#{name}, would you like to continue playing? (y/n)"
  continue = gets.chomp.downcase
  i = 0
  loop do
    break if %w(y n).include?(continue) || i > 2
    puts "That is not a valid selection. Would you like to continue? (y/n)"
    continue = gets.chomp.downcase
    i += 1
  end
  continue
end

def final_message(balance, stand, stand2, player_total2)
  puts "\nYou have lost all of your money." if balance == 0 && stand &&
                                               (stand2 || player_total2 == 0)
  if balance >= 1000 && stand && (stand2 || player_total2 == 0)
    puts "\nYour balance has reached $1000! You have been banned from Launch School Casinos."
  end
  puts "Goodbye.\n\n\n"
end

def player_turn(deck, balance, player_cards, player_cards2, dealer_cards, player_total,
                player_total2, dealer_total, bet, bet2, stand, stand2)
  if player_cards.empty?
    bet, balance = initial_prompt(balance)
    player_cards, dealer_cards, player_total, dealer_total = deal_cards(deck)
    update_display(balance, player_cards, player_cards2, dealer_cards,
                   player_total, player_total2, dealer_total, stand, stand2, bet, bet2)
  else
    unless stand
      deck, player_cards, player_cards2, player_total, player_total2, balance, bet, bet2, stand =
        first_hand_turn(player_total2, deck, balance, player_cards, player_cards2, player_total,
                        bet, bet2, stand, stand2, dealer_cards, dealer_total)
    end
    if player_cards2.length > 1 && !stand2
      deck, player_cards, player_cards2, player_total, player_total2, balance, bet, bet2, stand2 =
        second_hand_turn(player_total2, deck, balance, player_cards, player_cards2, player_total,
                         bet, bet2, stand, stand2, dealer_cards, dealer_total)
    end
    if player_cards2.length == 1
      deck, player_cards, player_cards2, player_total, player_total2 =
        second_hand_first_turn(player_total2, deck, balance, player_cards,
                               player_cards2, player_total, bet, bet2, stand,
                               stand2, dealer_cards, dealer_total)
    end
  end
  [bet, balance, player_cards, dealer_cards, player_total, dealer_total,
   deck, player_cards2, player_total2, bet2, stand, stand2]
end

def first_hand_turn(player_total2, deck, balance, player_cards, player_cards2,
                    player_total, bet, bet2, stand, stand2, dealer_cards, dealer_total)
  print "(For first hand)" unless player_total2 == 0
  deck, player_cards, player_cards2, player_total, player_total2, balance, bet, bet2, stand =
    update_hand(deck, balance, player_cards, player_cards2, player_total,
                player_total2, bet, bet2, stand)
  update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                 player_total2, dealer_total, stand, stand2, bet, bet2)
  [deck, player_cards, player_cards2, player_total, player_total2, balance, bet, bet2, stand]
end

def second_hand_first_turn(player_total2, deck, balance, player_cards, player_cards2,
                           player_total, bet, bet2, stand, stand2, dealer_cards, dealer_total)
  update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                 player_total2, dealer_total, stand, stand2, bet, bet2)
  deck, player_cards, player_total = hit(deck, player_cards, player_total)
  sleep 1
  update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                 player_total2, dealer_total, stand, stand2, bet, bet2)
  deck, player_cards2, player_total2 = hit(deck, player_cards2, player_total2)
  sleep 1
  update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                 player_total2, dealer_total, stand, stand2, bet, bet2)
  [deck, player_cards, player_cards2, player_total, player_total2]
end

def second_hand_turn(player_total2, deck, balance, player_cards, player_cards2,
                     player_total, bet, bet2, stand, stand2, dealer_cards, dealer_total)
  print '(For second hand)'
  deck, player_cards2, player_cards, player_total2, player_total, balance, bet2, bet, stand2 \
    = update_hand(deck, balance, player_cards2, player_cards, player_total2,
                  player_total, bet2, bet, stand2)
  sleep 1
  update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                 player_total2, dealer_total, stand, stand2, bet, bet2)
  [deck, player_cards, player_cards2, player_total, player_total2, balance, bet, bet2, stand2]
end

def dealer_turn(stand, player_cards2, stand2, dealer_total, player_total, player_total2,
                deck, dealer_cards, balance, player_cards, bet, bet2)
  if stand && (player_cards2.empty? || stand2)
    loop do
      break if dealer_total >= 17 || player_doesnt_care?(player_total, player_total2)
      deck, dealer_cards, dealer_total = hit(deck, dealer_cards, dealer_total)
      update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                     player_total2, dealer_total, stand, stand2, bet, bet2)
    end
  end
  [deck, dealer_cards, dealer_total]
end

def check_game_status(dealer_total, player_total, player_total2, stand, stand2)
  stand = true if dealer_total == HAND_LIMIT || player_total > HAND_LIMIT || player_total == HAND_LIMIT
  stand2 = true if player_total2 > HAND_LIMIT || player_total2 == HAND_LIMIT
  [stand, stand2]
end

def resolve_game(dealer_cards, player_total, player_total2, dealer_total, name, balance,
                 player_cards, player_cards2, stand, stand2, bet, bet2)
  dealer_total = dealer_cards[0][2] if player_doesnt_care?(player_total, player_total2)
  update_display(balance, player_cards, player_cards2, dealer_cards, player_total,
                 player_total2, dealer_total, stand, stand2, bet, bet2)
  balance = winning_message(player_total, player_total2, dealer_total, bet, bet2, balance, name)
  sleep 1
  balance
end


# Set initial variable scope outside main loop
deck = initialize_deck
balance = 100
continue = "y"
player_total = player_total2 = dealer_total = bet = bet2 = 0
player_cards = player_cards2 = dealer_cards = []
stand = stand2 = continue = false
name = prompt_user_name
intro(name)

# Main loop
loop do
  if continue == 'y'
    deck, player_cards, player_cards2, dealer_cards, player_total, player_total2,
    dealer_total, bet, bet2, stand, stand2, continue = initialize_variables
  end

  bet, balance, player_cards, dealer_cards, player_total, dealer_total,
  deck, player_cards2, player_total2, bet2, stand, stand2 =
    player_turn(deck, balance, player_cards, player_cards2, dealer_cards, player_total,
                player_total2, dealer_total, bet, bet2, stand, stand2)

  stand, stand2 = check_game_status(dealer_total, player_total, player_total2, stand, stand2)

  deck, dealer_cards, dealer_total = dealer_turn(stand, player_cards2, stand2, dealer_total,
                                                 player_total, player_total2, deck, dealer_cards,
                                                 balance, player_cards, bet, bet2)

  next unless stand && (stand2 || player_total2 == 0)
  balance = resolve_game(dealer_cards, player_total, player_total2, dealer_total, name, balance,
                         player_cards, player_cards2, stand, stand2, bet, bet2)
  continue = (1..999).cover?(balance) ? prompt_continue?(name) : false
  break if continue == 'n' || !(1..999).cover?(balance)
end

final_message(balance, stand, stand2, player_total2)
