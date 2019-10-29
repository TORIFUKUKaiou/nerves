defmodule Nerves.EnvTest do
  use NervesTest.Case, async: false
  alias Nerves.Env

  test "populate Nerves env" do
    in_fixture("simple_app", fn ->
      packages =
        ~w(system toolchain system_platform toolchain_platform)
        |> Enum.sort()

      env_pkgs =
        packages
        |> load_env
        |> Enum.map(& &1.app)
        |> Enum.map(&Atom.to_string/1)
        |> Enum.sort()

      assert packages == env_pkgs
    end)
  end

  test "determine host arch" do
    assert Env.parse_arch("win32") == "x86_64"
    assert Env.parse_arch("x86_64-apple-darwin14.1.0") == "x86_64"
    assert Env.parse_arch("armv7l-unknown-linux-gnueabihf") == "arm"
    assert Env.parse_arch("unknown") == "x86_64"
  end

  test "determine host platform" do
    assert Env.parse_platform("win32") == "win"
    assert Env.parse_platform("x86_64-apple-darwin14.1.0") == "darwin"
    assert Env.parse_platform("x86_64-unknown-linux-gnu") == "linux"

    assert_raise Mix.Error, fn ->
      Env.parse_platform("unknown")
    end
  end

  test "override host os and host arch" do
    System.put_env("HOST_OS", "rpi")
    assert Nerves.Env.host_os() == "rpi"
    System.delete_env("HOST_OS")
    System.put_env("HOST_ARCH", "arm")
    assert Nerves.Env.host_arch() == "arm"
    System.delete_env("HOST_ARCH")
  end

  test "compiling Nerves packages from the top of an umbrella raises an error" do
    in_fixture("umbrella", fn ->
      File.cwd!()
      |> Path.join("mix.exs")
      |> Code.require_file()

      Mix.Tasks.Deps.Get.run([])

      assert_raise Mix.Error, fn ->
        Mix.Tasks.Nerves.Precompile.run([])
        Mix.Tasks.Compile.run([])
      end
    end)
  end

  describe "data_dir/0" do
    test "prefers NERVES_DATA_DIR over XDG_DATA_HOME" do
      System.put_env("NERVES_DATA_DIR", "nerves_data_dir")
      System.put_env("XDG_DATA_HOME", "xdg_data_home")
      assert "nerves_data_dir" = Nerves.Env.data_dir()
    end

    test "falls back to XDG_DATA_HOME/nerves" do
      System.delete_env("NERVES_DATA_DIR")
      System.put_env("XDG_DATA_HOME", "xdg_data_home")
      assert :filename.basedir(:user_data, "nerves") == Nerves.Env.data_dir()
    end

    test "falls back to $HOME/.nerves" do
      System.delete_env("NERVES_DATA_DIR")
      System.delete_env("XDG_DATA_HOME")
      assert Path.expand("~/.nerves") == Nerves.Env.data_dir()
    end
  end
end
