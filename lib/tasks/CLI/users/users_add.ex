defmodule Mix.Tasks.CLI.UsersAdd do
  def run(args) do
    args = Mix.Tasks.CLI.Utils.args_to_map(args)

    case args do
      %{"--help" => _} -> Mix.Tasks.CLI.Utils.print_help_for("users add")
      x when x == %{} -> add_user()
      _ -> IO.puts "boreale cli: users add command does not take any arguments"
           IO.puts "See 'boreale cli users add --help'"
    end
  end

  defp add_user do
    username = IO.gets("username: ") |> String.trim
    password = password_prompt("password:") |> String.trim

    if (String.length(username) >= 3 and String.length(password) >= 6) do
      case insert_user({username, password}) do
       {:ok} -> IO.puts "User #{username} has been added."
       {:error, msg} -> IO.puts msg
      end
    else
      IO.puts "Username have to be at least three characters long."
      IO.puts "Password have to be at least six characters long."
    end
  end

  defp insert_user({u, p}) do
    date_time = DateTime.utc_now()
    {:ok, table} =
      File.cwd!
      |> Path.join("data/users.dets")
      |> String.to_atom()
      |> :dets.open_file([type: :set])

    created? = :dets.insert_new(table, {u, Bcrypt.hash_pwd_salt(p), date_time})
    :dets.close(table)

    if created?, do: {:ok}, else: {:error, "The user #{u} already exists."}
  end

   # Password prompt that hides input by every 1ms
  # clearing the line with stderr
  #
  # taken from the hex repository
  # https://github.com/hexpm/hex/blob/ae70158bb7c96f2d95b15c5b64c1899f8188e2d8/lib/mix/tasks/hex.ex#L363
  defp password_prompt(prompt) do
    pid = spawn_link(fn -> clear_password(prompt) end)
    ref = make_ref()
    value = IO.gets(prompt <> " ")

    send(pid, {:done, self(), ref})
    receive do: ({:done, ^pid, ^ref} -> :ok)

    value
  end

  defp clear_password(prompt) do
    receive do
      {:done, parent, ref} ->
        send(parent, {:done, self(), ref})
        IO.write(:standard_error, "\e[2K\r")
    after
      1 ->
        IO.write(:standard_error, "\e[2K\r#{prompt} ")
        clear_password(prompt)
    end
  end
end
