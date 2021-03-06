defmodule LiveTest.Chess.AIWebApi do
  @moduledoc """
  A module that allows chess moves to be generated
  from querying a web API.

  By passing a FEN-encoded chess game to a chess engine
  or chess database, it may be possible to build an
  incredible strong chess AI using moves from ML trained
  engines, without having to train a model yourself.

  # TODO: Find a better web API to request moves from.
  """
  alias LiveTest.Chess.Move
  require Logger

  @url "https://www.chessdb.cn/cdb.php"


  @doc """
  Finds the best move for the given chess FEN using a web
  API. The chess DB in the URL above servers requests based
  on an 8TB database of chess knowledge, and falls back to
  the Stockfish chess engine.
  """
  @spec find_move(binary, any) :: %LiveTest.Chess.Move{
          display_name: binary,
          source: binary,
          target: binary
        }
  def find_move(fen, turn \\ nil) do
    case get_move_from_api(fen) do
      nil ->
        # Fallback to random or minimax move
        LiveTest.Chess.AILevelZero.find_move(fen, turn)
      move ->
        source = String.slice(move, 0..1)
        target = String.slice(move, 2..3)
        %Move{source: source, target: target, display_name: move}
    end
  end

  defp get_move_from_api(fen) do
    request = @url <> "?action=querybest" <> "&board=#{URI.encode(fen)}" <> "&json=1"
    case HTTPoison.get(request) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode!(body) do
          %{"status" => "nobestmove"} ->
            nil
          %{"move" => move} ->
            move
        end
      error ->
        Logger.error("Bad response from stockfish API: #{inspect(error)}")
        nil
    end
  end

end
