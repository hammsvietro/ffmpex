defmodule FFmpexTest do
  use ExUnit.Case
  doctest FFmpex

  @fixture Path.join(__DIR__, "fixtures/test-mpeg.mpg")
  @output_path Path.join(System.tmp_dir, "ffmpex-test-fixture.avi")

  import FFmpex
  use FFmpex.Options

  setup do
    on_exit fn ->
      File.rm @output_path
    end
  end

  # ffmpeg -i input.avi -b:v 64k -bufsize 64k output.avi
  test "set bitrate runs successfully" do
    command =
      FFmpex.new_command
      |> add_global_option(option_y())
      |> add_input_file(@fixture)
      |> add_output_file(@output_path)
        |> add_stream_specifier(stream_type: :video)
          |> add_stream_option(option_b("64k"))
        |> add_file_option(option_maxrate("128k"))
        |> add_file_option(option_bufsize("64k"))

    assert {:ok, _} = execute(command)
  end

  test "get error with invalid options" do
    command =
      FFmpex.new_command
      |> add_global_option(option_maxrate(-100))

    assert {:error, {_, 1}} = execute(command)
  end

  test "raise if invalid option context" do
    assert_raise ArgumentError, fn ->
      FFmpex.new_command
      |> add_global_option(option_f("mpegts"))
    end
  end

  test "manually specified option struct" do
    manual_option = %FFmpex.Option{name: "-strict", argument: "very"}

    command =
      FFmpex.new_command
      |> add_global_option(option_y())
      |> add_global_option(manual_option)
      |> add_input_file(@fixture)
      |> add_output_file(@output_path)

    assert {:ok, _} = execute(command)
  end

  test "error if invalid manual option name" do
    manual_option = %FFmpex.Option{name: "-thisisabadoptionitshouldfail", argument: "lolololol"}

    command =
      FFmpex.new_command
      |> add_global_option(manual_option)
      |> add_input_file(@fixture)
      |> add_output_file(@output_path)

    assert {:error, {_, 1}} = execute(command)
  end

  test "can prepare arguments" do
    command =
      FFmpex.new_command
      |> add_global_option(option_y())
      |> add_input_file(@fixture)
      |> add_output_file(@output_path)
        |> add_stream_specifier(stream_type: :video)
          |> add_stream_option(option_b("64k"))
        |> add_file_option(option_maxrate("128k"))
        |> add_file_option(option_bufsize("64k"))

    assert {executable, args} = prepare(command)
    assert Enum.count(args) ==  10
    assert executable =~  "ffmpeg"
  end

  test "can get output from stdout" do
    command =
      FFmpex.new_command()
      |> add_input_file(@fixture) 
      |> to_stdout()
        |> add_file_option(option_f("avi"))

    assert {:ok, stdout_binary} = execute(command)
    assert is_binary(stdout_binary)
  end
end
