require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

#--------------------PRE-GAME-CODE--------------------------------#

get '/' do
  session.clear
  session[:page_id] = 'home'
  session[:game_state] = 'pre'
  erb :homepage
end

get '/enter_details' do
  session[:page_id] = 'enter details'
  erb :enter_details
end

post '/enter_details' do
  session[:name] = params['name']
  redirect '/bet'
end

#-----------------------BETTING-CODE-----------------------------#

get '/bet' do
  redirect '/game_over' if session[:total_coin] == 0
  session[:bet_state] = nil
  if session[:game_state] != 'mid'
    session[:total_coin] = 100
    session[:page_id] = 'bet'
    erb :bet
  else
    session[:page_id] = 'bet'
    erb :bet
  end
end

post '/bet' do
  bet = params['bet_amount'].to_i
  total_money = session[:total_coin].to_i
  if bet == 0 
    @error = "Please enter a bet amount"
    erb :bet
  elsif bet <= total_money
    session[:current_bet] = bet
    session[:total_coin] = total_money - bet
    redirect '/play'
  else
    @error = "You don't have that much money!"
    erb :bet
  end
end

#-----------------------GAMEPLAY-CODE-----------------------------------#
before do
@show_hit_or_stay_buttons = true
session[:bet_state] = nil
winners if session[:game_state] == 'mid'
end

#---------------------Helpers------------------------------#

helpers do

  def create_deck
    deck = []
    %w[2 3 4 5 6 7 8 9 10 jack queen king ace].each do |face|
      %w[hearts diamonds clubs spades].each do |suit|
        deck << "#{face} of #{suit}"
      end
    end
    deck.shuffle!
  end

  def calculate_total(whos_cards)
    count = 0
    whos_cards.each do |card|
      value = card.split().first
      if value == "king" || value == "queen" || value == "jack"
        count = count + 10
      elsif value == "ace"
        count = count + 11
      else
        count = count + value.to_i
      end
    end
    whos_cards.count { |card| card.split().first == "ace"}.times do
      break if count <=21
      count -= 10
    end
    count
  end

  def image_url(card)
    face = card.split().first
    suit = card.split().last
    "<img src='/images/cards/#{suit}_#{face}.jpg'>"
  end

  def winners   
    players = calculate_total(session[:players_cards])
    dealers = calculate_total(session[:dealers_cards])
    if session[:turn] == 'players'
      if players == 21
        "Player"
        session[:bet_state] = 'win'
      elsif players > 21
        "Dealer"
        session[:bet_state] = 'lose'
      end
    elsif session[:turn] == 'dealers'
      if dealers == 21
        "Dealer"
        session[:bet_state] = 'lose'
      elsif dealers > 21
        "Player"
        session[:bet_state] = 'win'
      elsif dealers > players
        "Dealer"
        session[:bet_state] = 'lose'
      elsif players == dealers
        "Tie"
        session[:bet_state] = 'tie'
      end
    end
  end
end

#--------------------------Posts------------------------#

post '/player/hit' do
  session[:players_cards] << session[:deck].pop
  winners
  if session[:bet_state]
    redirect '/result'
  else
    erb :game
  end
end

post '/player/stay' do
  session[:turn] = 'dealers'
  session[:dealer] = nil
  redirect '/dealer/logic'
end

post '/dealer/hit' do
  session[:dealers_cards] << session[:deck].pop
  if session[:bet_state]
    redirect '/result'
  else
    redirect '/dealer/logic'
  end
end

#---------------------------Gets----------------------------#

get '/dealer' do
  redirect '/result' if session[:bet_state]
  erb :game
end

get '/dealer/logic' do
  if calculate_total(session[:dealers_cards]) < calculate_total(session[:players_cards]) && calculate_total(session[:dealers_cards]) <= 17
    session[:dealer] = 'hit'
    redirect '/dealer'
  elsif session[:bet_state] 
    redirect '/result'
  end
  session[:dealer] = 'stay'
  redirect '/result'
end

get '/play' do
  session[:bet_state] = nil
  session[:game_state] = 'mid'
  session[:page_id] = 'play'
  session[:deck] = create_deck
  session[:turn] = 'players'
  session[:players_cards] = []
  session[:dealers_cards] =[]
  session[:players_cards] << session[:deck].pop
  session[:players_cards] << session[:deck].pop
  session[:dealers_cards] << session[:deck].pop
  session[:game_state] = 'mid'
  winners
  if session[:bet_state]
    redirect '/result'
  end
  session[:dealers_cards] << session[:deck].pop
  erb :game
end

get "/result" do
  @show_hit_or_stay_buttons = false
  session[:dealer] = 'stay'
  if (session[:bet_state] == 'win')
    session[:total_coin] += (2*session[:current_bet])
    session[:current_bet] = 0
    @success = "Player Wins! <a href='/bet'>Play Again?</a>"
  elsif (session[:bet_state] == 'lose')
    session[:current_bet] = 0
    @error = "Dealer Wins! <a href='/bet'>Play Again?</a>"
  elsif (session[:bet_state] == 'tie')
    session[:total_coin] += session[:current_bet]
    session[:current_bet] = 0
    @error = "It's a Tie <a href='/bet'>Play Again?</a>"
  else
    session[:total_coin] += (2*session[:current_bet])
    session[:current_bet] = 0
    @success = "Player Wins! <a href='/bet'>Play Again?</a>"
  end
  erb :game
end

get '/game_over' do
  @show_hit_or_stay_buttons = false
  @error = "You're fresh outta cash! <a href='/'>Start Over?</a>"
  erb :game
end