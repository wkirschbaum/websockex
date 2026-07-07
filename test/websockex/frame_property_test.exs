defmodule WebSockex.FramePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias WebSockex.Frame

  @valid_result_msg "expected :incomplete | {:ok, _, _} | {:error, %FrameError{}}"

  defp valid_result?(result) do
    result == :incomplete or match?({:ok, _, _}, result) or
      match?({:error, %WebSockex.FrameError{}}, result)
  end

  # Build an unmasked (server -> client) frame on the wire.
  defp unmasked(opcode, payload) do
    len = byte_size(payload)

    length_bits =
      cond do
        len <= 125 -> <<len::7>>
        len <= 0xFFFF -> <<126::7, len::16>>
        true -> <<127::7, len::64>>
      end

    <<1::1, 0::3, opcode::4, 0::1, length_bits::bitstring, payload::binary>>
  end

  defp unmask(key, payload), do: unmask(key, payload, <<>>)
  defp unmask(_key, <<>>, acc), do: acc

  defp unmask(<<k::8, rest_key::binary>>, <<b::8, rest::binary>>, acc) do
    unmask(rest_key <> <<k>>, rest, acc <> <<Bitwise.bxor(b, k)::8>>)
  end

  property "parse_frame/1 never raises on arbitrary bytes" do
    check all(bin <- binary()) do
      assert valid_result?(Frame.parse_frame(bin)), @valid_result_msg
    end
  end

  property "parse_frame/2 never raises on arbitrary bytes with any max size" do
    check all(bin <- binary(), max <- integer(0..2000)) do
      assert valid_result?(Frame.parse_frame(bin, max)), @valid_result_msg
    end
  end

  property "parse_frame/1 never raises on arbitrary bitstrings" do
    check all(bits <- bitstring()) do
      assert valid_result?(Frame.parse_frame(bits)), @valid_result_msg
    end
  end

  property "round-trips unmasked binary frames" do
    check all(payload <- binary()) do
      assert Frame.parse_frame(unmasked(2, payload)) == {:ok, {:binary, payload}, ""}
    end
  end

  property "round-trips unmasked text frames" do
    check all(payload <- string(:printable)) do
      assert Frame.parse_frame(unmasked(1, payload)) == {:ok, {:text, payload}, ""}
    end
  end

  property "returns trailing bytes after a complete frame as the remainder" do
    check all(payload <- binary(), rest <- binary()) do
      assert Frame.parse_frame(unmasked(2, payload) <> rest) == {:ok, {:binary, payload}, rest}
    end
  end

  property "any strict prefix of a single frame is incomplete" do
    check all(
            payload <- binary(min_length: 1),
            frame = unmasked(2, payload),
            split <- integer(0..(byte_size(frame) - 1))
          ) do
      <<prefix::binary-size(^split), _::binary>> = frame
      assert Frame.parse_frame(prefix) == :incomplete
    end
  end

  property "encoded frames carry the original payload once unmasked" do
    check all(payload <- binary(max_length: 125)) do
      {:ok, <<_::9, _len::7, mask::binary-size(4), masked::binary>>} =
        Frame.encode_frame({:binary, payload})

      assert unmask(mask, masked) == payload
    end
  end

  property "rejects frames declaring a payload larger than the max frame size" do
    check all(
            payload <- binary(min_length: 1),
            max <- integer(0..(byte_size(payload) - 1))
          ) do
      assert {:error, %WebSockex.FrameError{reason: :frame_too_large}} =
               Frame.parse_frame(unmasked(2, payload), max)
    end
  end

  property "accepts frames within the max frame size" do
    check all(payload <- binary()) do
      assert Frame.parse_frame(unmasked(2, payload), byte_size(payload)) ==
               {:ok, {:binary, payload}, ""}
    end
  end
end
