defmodule Tictac.GameState do
  @moduledoc """
  Model the game state for a tic-tac-toe game.
  """
  alias Tictac.Square
  alias Tictac.Player
  alias __MODULE__

  # The board's squares are addressible using an atom like this: `:sq11` for
  # "Square: Row 1, Column 1". Ths goes through `:sq33` for "Square: Row 3,
  # Column 3".
  defstruct players: [],
            player_turn: nil,
            status: :not_started,
            board: [
              # Row 1
              Square.build(:sq11),
              Square.build(:sq12),
              Square.build(:sq13),
              # Row 2
              Square.build(:sq21),
              Square.build(:sq22),
              Square.build(:sq23),
              # Row 3
              Square.build(:sq31),
              Square.build(:sq32),
              Square.build(:sq33)
            ]

  @type t :: %GameState{
          status: :not_started | :playing | :done,
          players: [Player.t()],
          player_turn: nil | integer(),
          board: [Square.t()]
        }

  @doc """
  Return an initialized GameState struct. Requires one player to start.
  """
  @spec new(Player.t()) :: t()
  def new(%Player{} = player) do
    %GameState{players: [player]}
  end

  @doc """
  Allow another player to join the game. Exactly 2 players are required to play.
  """
  @spec join_game(t(), Player.t()) :: {:ok, t()} | {:error, String.t()}
  def join_game(%GameState{players: []} = _state, %Player{}) do
    {:error, "Can only join a created game"}
  end

  def join_game(%GameState{players: [_p1, _p2]} = _state, %Player{} = _player) do
    {:error, "Only 2 players allowed"}
  end

  def join_game(%GameState{players: [p1]} = state, %Player{} = player) do
    player =
      if p1.letter == "O" do
        %Player{player | letter: "X"}
      else
        %Player{player | letter: "O"}
      end

    {:ok, %GameState{state | players: [p1, player]}}
  end

  @doc """
  Start the game.
  """
  def start(%GameState{status: :playing}), do: {:error, "Game in play"}
  def start(%GameState{status: :done}), do: {:error, "Game is done"}

  def start(%GameState{status: :not_started, players: [_p1, _p2]} = state) do
    {:ok, %GameState{state | status: :playing, player_turn: "O"}}
  end

  def start(%GameState{players: _players}), do: {:error, "Missing players"}

  @doc """
  Return a boolean value for if it is currently the given player's turn.
  """
  @spec player_turn?(t(), Player.t()) :: boolean()
  def player_turn?(%GameState{player_turn: turn}, %Player{letter: letter}) when turn == letter,
    do: true

  def player_turn?(%GameState{}, %Player{}), do: false

  @doc """
  Check to see if the player won. Return a tuple of the winning squares if the they won. If no win found, returns `:not_found`.

  Tests for all the different ways the player could win.
  """
  @spec check_for_player_win(t(), Player.t()) :: :not_found | {atom(), atom(), atom()}
  def check_for_player_win(%GameState{board: board}, %Player{letter: letter}) do
    case board do
      #
      # Check for all the straight across wins
      [%Square{letter: ^letter}, %Square{letter: ^letter}, %Square{letter: ^letter} | _] ->
        {:sq11, :sq12, :sq13}

      [_, _, _, %Square{letter: ^letter}, %Square{letter: ^letter}, %Square{letter: ^letter} | _] ->
        {:sq21, :sq22, :sq23}

      [
        _,
        _,
        _,
        _,
        _,
        _,
        %Square{letter: ^letter},
        %Square{letter: ^letter},
        %Square{letter: ^letter}
      ] ->
        {:sq31, :sq32, :sq33}

      #
      # Check for all the vertical wins
      [
        %Square{letter: ^letter},
        _,
        _,
        %Square{letter: ^letter},
        _,
        _,
        %Square{letter: ^letter},
        _,
        _ | _
      ] ->
        {:sq11, :sq21, :sq31}

      [
        _,
        %Square{letter: ^letter},
        _,
        _,
        %Square{letter: ^letter},
        _,
        _,
        %Square{letter: ^letter},
        _ | _
      ] ->
        {:sq12, :sq22, :sq32}

      [
        _,
        _,
        %Square{letter: ^letter},
        _,
        _,
        %Square{letter: ^letter},
        _,
        _,
        %Square{letter: ^letter} | _
      ] ->
        {:sq13, :sq23, :sq33}

      #
      # Check for the diagonal wins
      [
        %Square{letter: ^letter},
        _,
        _,
        _,
        %Square{letter: ^letter},
        _,
        _,
        _,
        %Square{letter: ^letter} | _
      ] ->
        {:sq11, :sq22, :sq33}

      [
        _,
        _,
        %Square{letter: ^letter},
        _,
        %Square{letter: ^letter},
        _,
        %Square{letter: ^letter},
        _,
        _ | _
      ] ->
        {:sq13, :sq22, :sq31}

      _ ->
        :not_found
    end
  end

  @doc """
  Return a list of all the squares that are a valid move given the current games
  state.
  """
  @spec valid_moves(t()) :: [atom()]
  def valid_moves(%GameState{board: board}) do
    Enum.reduce(board, [], fn square, acc ->
      if Square.is_open?(square) do
        [square.name | acc]
      else
        acc
      end
    end)
  end

  @doc """
  Check for who the game's result. Either a player won, the game ended in a
  draw, or the game is still going.
  """
  @spec result(t()) :: :playing | :draw | Player.t()
  def result(%GameState{players: [p1, p2]} = state) do
    player_1_won =
      case check_for_player_win(state, p1) do
        :not_found -> false
        {_, _, _} -> true
      end

    player_2_won =
      case check_for_player_win(state, p2) do
        :not_found -> false
        {_, _, _} -> true
      end

    cond do
      player_1_won -> p1
      player_2_won -> p2
      valid_moves(state) == [] -> :draw
      true -> :playing
    end
  end

  @doc """
  Performs a player move. Returns a new GameState after the move. Will be the
  next player's turn. Returns an error tuple if the move is not allowed or not
  the player's turn.
  """
  @spec move(t() | {:ok, t()}, Player.t(), square :: atom()) :: {:ok, t()} | {:error, String.t()}
  def move({:ok, %GameState{} = state}, %Player{} = player, square) do
    move(state, player, square)
  end

  def move(%GameState{} = state, %Player{} = player, square) do
    # - verify player's turn
    # - new board with the player's letter in the square
    # - check for a win/draw
    # - if more moves are posible,
    # - set to the next player's turn
    state
    |> verify_player_turn(player)
    |> verify_square(square)
    |> place_letter(player, square)
    |> check_for_done()
    |> next_player_turn()
  end

  defp verify_player_turn(%GameState{} = state, %Player{} = player) do
    if player_turn?(state, player) do
      {:ok, state}
    else
      {:error, "Not your turn!"}
    end
  end

  # defp verify_square({:ok, %GameState{board: board} = state}, square) do
  #   # Verify

  # end

  defp place_letter({:ok, %GameState{board: board} = state}, %Player{} = player, square) do
    # TODO: Create a local function that does a pattern match. Return an error if the matching square name already has a letter.
    # TODO: Return an updated square if valid
    # TODO: Return existing square if not a name match
    # TODO: do as a public function with doctest? Do @doc false and write the tests for that function

    updated_board =
      Enum.map(board, fn sq ->
        if sq.name == square do
          %Square{sq | letter: player.letter}
        else
          sq
        end
      end)

    {:ok, %GameState{state | board: updated_board}}
  end

  defp place_letter({:error, _reason} = error, _player, _square), do: error

  defp check_for_done({:ok, %GameState{} = state}) do
    case result(state) do
      :playing ->
        {:ok, state}

      _game_done ->
        {:ok, %GameState{state | status: :done}}
    end
  end

  defp check_for_done({:error, _reason} = error), do: error

  defp next_player_turn({:error, _reason} = error), do: error

  defp next_player_turn({:ok, %GameState{player_turn: turn} = state}) do
    {:ok, %GameState{state | player_turn: if(turn == "X", do: "O", else: "X")}}
  end
end
