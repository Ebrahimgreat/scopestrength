defmodule ScopestrengthWeb.ClientDashboard do
alias Scopestrength.Programmes.ProgrammeUser
alias Scopestrength.Programmes
alias Scopestrength.Programmes.Programme
alias Scopestrength.Accounts.Trainer
alias Scopestrength.Clients.Client
alias Scopestrength.DownloadProgramme
alias Scopestrength.Invites
alias Scopestrength.Repo
alias Scopestrength.Training.{Workout, WorkoutDetails}
import Ecto.Query
  use ScopestrengthWeb, :live_view


  def handle_event("searchProgress", %{"q" => query}, socket) do
    query = String.trim(query || "")
    {:noreply,
     assign(socket,
       progress_query: query,
       exercise_progress: filter_progress(socket.assigns.all_exercise_progress, query)
     )}
  end

  def handle_event("submit_invite_code", %{"code" => code}, socket) do
    user = socket.assigns.current_user
    client = socket.assigns.client

    case Invites.redeem_invite(code, user.email) do
      {:ok, trainer_id} ->
        case Invites.link_client_to_trainer(client.id, trainer_id) do
          {:ok, updated_client} ->
            client = Repo.get!(Client, client.id) |> Repo.preload(trainer: :user)
            {:noreply, socket
              |> assign(client: client, invite_code: "")
              |> put_flash(:info, "Successfully linked with your trainer!")}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, "Failed to link with trainer")}
        end

      {:error, :invalid_code} ->
        {:noreply, socket |> put_flash(:error, "Invalid invite code")}

      {:error, :already_used} ->
        {:noreply, socket |> put_flash(:error, "This invite code has already been used")}

      {:error, :email_mismatch} ->
        {:noreply, socket |> put_flash(:error, "This invite code was created for a different email address")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Something went wrong")}
    end
  end

  def handle_event("update_invite_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, invite_code: code)}
  end

  def handle_event("downloadProgramme", _, socket) do
    programme =
    Repo.get!(Programme, socket.assigns.current_programme.programme_id)
    |> Repo.preload(programmeTemplates: [programmeDetails: :exercise])
    DownloadProgramme.downloadProgramme(%{programme: programme})
     {:noreply, assign(socket, report: true)}
    end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id}) |> Repo.preload(trainer: :user)

    currentProgramme =
      from(pu in ProgrammeUser,
        where: pu.client_id == ^client.id and pu.is_active == true,
        order_by: [desc: pu.inserted_at],
        limit: 1
      )
      |> Repo.one()
      |> case do
        nil -> nil
        pu -> Repo.preload(pu, [programme: [programmeTemplates: [programmeDetails: :exercise]]])
      end


    # Get recent workouts
    recent_workouts =
      from(w in Workout,
        where: w.client_id == ^client.id,
        order_by: [desc: w.date],
        limit: 5,
        preload: [workoutDetails: :exercise]
      )
      |> Repo.all()

    # Get exercise progress (unique exercises the client has done)
    exercise_progress =
      from(wd in WorkoutDetails,
        join: w in Workout, on: wd.workout_id == w.id,
        where: w.client_id == ^client.id,
        join: e in assoc(wd, :exercise),
        left_join: m in assoc(e, :muscle),
        group_by: [e.id, e.name, m.name],
        order_by: [desc: count(wd.id)],
        select: %{
          exercise_id: e.id,
          name: e.name,
          muscle_name: m.name,
          total_sets: count(wd.id)
        }
      )
      |> Repo.all()


    templates =
      case currentProgramme do
        nil -> []
        pu -> pu.programme.programmeTemplates
      end

    {:ok, assign(socket,
      report: false,
      client: client,
      current_programme: currentProgramme,
      template_count: length(templates),
      programme_progress: programme_progress(templates, recent_workouts),
      invite_code: "",
      recent_workouts: recent_workouts,
      exercise_progress: exercise_progress,
      all_exercise_progress: exercise_progress,
      progress_query: ""
    )}
  end

  # The schema has no week count or duration, so "progress" is the share of the
  # programme's templates the client has actually trained, matched by name.
  defp programme_progress([], _workouts), do: 0

  defp programme_progress(templates, workouts) do
    trained =
      workouts
      |> Enum.map(&String.downcase(&1.name || ""))
      |> MapSet.new()

    matched =
      Enum.count(templates, fn template ->
        MapSet.member?(trained, String.downcase(template.name || ""))
      end)

    round(matched / length(templates) * 100)
  end

  defp workout_volume(workout) do
    workout.workoutDetails
    |> Enum.map(fn d -> (d.reps || 0.0) * (d.weight || 0.0) end)
    |> Enum.sum()
    |> then(fn total ->
      if total >= 1000, do: "#{Float.round(total / 1000, 1)}k", else: round(total)
    end)
  end
  def handle_info(_, socket), do: {:noreply, socket}

  # Matches exercise and muscle name, so the removed muscle chips are not missed.
  defp filter_progress(entries, ""), do: entries

  defp filter_progress(entries, query) do
    needle = String.downcase(query)

    Enum.filter(entries, fn entry ->
      [entry.name, entry.muscle_name]
      |> Enum.any?(fn value -> value && String.contains?(String.downcase(value), needle) end)
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="num text-xs font-medium uppercase tracking-widest text-dim">
            <%= Calendar.strftime(DateTime.utc_now(), "%A, %B %d") %>
          </p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Dashboard
          </h1>
        </div>

        <.link
          navigate={~p"/client/settings"}
          class="flex shrink-0 items-center gap-3 rounded-lg border border-line px-3 py-2 transition hover:border-dim"
        >
          <%= if @client.profile_picture_url do %>
            <img
              src={@client.profile_picture_url}
              alt=""
              class="h-9 w-9 rounded-full border border-line object-cover"
            />
          <% else %>
            <span class="flex h-9 w-9 items-center justify-center rounded-full bg-secondary text-sm font-bold text-primary">
              <%= get_user_initials(@client) %>
            </span>
          <% end %>
          <span class="text-left">
            <%= if @client.trainer do %>
              <span class="block text-xs text-dim">Trainer</span>
              <span class="block text-sm font-medium text-foreground">
                <%= @client.trainer.user.name %>
              </span>
            <% else %>
              <span class="block text-sm text-warning">No trainer</span>
            <% end %>
          </span>
        </.link>
      </div>

      <div :if={@client.trainer == nil} class="mt-8 rounded-xl border border-line bg-card p-5">
        <h2 class="text-sm font-semibold text-foreground">Have an invite code?</h2>
        <p class="mt-1 text-sm text-dim">
          Enter the code from your trainer to connect with them.
        </p>
        <form phx-submit="submit_invite_code" class="mt-4 flex flex-wrap gap-3">
          <input
            type="text"
            name="code"
            value={@invite_code}
            phx-change="update_invite_code"
            placeholder="ABC12345"
            aria-label="Invite code"
            class="num min-w-0 flex-1 rounded-md border-line bg-muted px-3 py-2.5 text-sm uppercase tracking-widest text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
          />
          <.button type="submit">Connect</.button>
        </form>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-4 lg:grid-cols-[1.4fr,1fr]">
        <div class="overflow-hidden rounded-xl border border-line bg-card">
          <div class="flex items-baseline justify-between gap-3 border-b border-line px-5 py-4">
            <h2 class="font-semibold text-foreground">Recent Sessions</h2>
            <.link
              navigate={~p"/client/workouts"}
              class="num text-xs uppercase tracking-widest text-dim transition hover:text-foreground"
            >
              View all →
            </.link>
          </div>

          <div
            :if={@recent_workouts == []}
            class="px-5 py-12 text-center text-sm text-dim"
          >
            No workouts logged yet.
          </div>

          <div :if={@recent_workouts != []} class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b border-line text-left">
                  <th class="num px-5 py-3 text-xs uppercase tracking-widest text-faint">Date</th>
                  <th class="num px-5 py-3 text-xs uppercase tracking-widest text-faint">Session</th>
                  <th class="num px-5 py-3 text-right text-xs uppercase tracking-widest text-faint">
                    Sets
                  </th>
                  <th class="num px-5 py-3 text-right text-xs uppercase tracking-widest text-faint">
                    Volume
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={workout <- @recent_workouts}
                  class="border-b border-line/60 transition last:border-0 hover:bg-secondary/50"
                >
                  <td class="num whitespace-nowrap px-5 py-4 text-sm text-dim">
                    <%= Calendar.strftime(workout.date || workout.inserted_at, "%b %d") %>
                  </td>
                  <td class="px-5 py-4">
                    <.link
                      navigate={~p"/client/workouts/#{workout.id}"}
                      class="font-medium text-primary transition hover:opacity-80"
                    >
                      <%= workout.name || "Training Session" %>
                    </.link>
                  </td>
                  <td class="num px-5 py-4 text-right text-sm text-foreground">
                    <%= length(workout.workoutDetails) %>
                  </td>
                  <td class="num whitespace-nowrap px-5 py-4 text-right text-sm text-foreground">
                    <%= workout_volume(workout) %><span class="ml-1 text-xs text-faint">kg</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="rounded-xl border border-line bg-card p-5">
          <p class="num text-xs uppercase tracking-widest text-dim">Current Programme</p>

          <%= if @current_programme do %>
            <h2 class="mt-3 font-display text-2xl font-bold uppercase tracking-wide text-foreground">
              <%= @current_programme.programme.name %>
            </h2>
            <p class="mt-2 text-sm text-dim">
              <%= if @client.trainer do %>
                Assigned by <%= @client.trainer.user.name %>
              <% else %>
                Self-assigned
              <% end %>
              · <%= @template_count %> template<%= if @template_count != 1, do: "s" %>
            </p>

            <%!-- No week/duration exists on the schema, so progress is measured
                  as distinct templates trained rather than an invented week count. --%>
            <div class="mt-5 h-1.5 w-full overflow-hidden rounded-full bg-muted">
              <div class="h-full rounded-full bg-primary" style={"width: #{@programme_progress}%"}>
              </div>
            </div>
            <p class="num mt-2 text-xs text-dim">
              <%= @programme_progress %>% of templates trained
            </p>

            <div class="mt-5 flex items-center gap-4 border-t border-line pt-4">
              <.link
                navigate={~p"/client/programmes"}
                class="text-xs font-medium text-dim transition hover:text-foreground"
              >
                View programme
              </.link>
              <%= if @report == false do %>
                <button
                  phx-click="downloadProgramme"
                  class="text-xs font-medium text-dim transition hover:text-foreground"
                >
                  Download PDF
                </button>
              <% else %>
                <a
                  href="/download/workout"
                  class="text-xs font-medium text-primary transition hover:opacity-80"
                >
                  Download now →
                </a>
              <% end %>
            </div>
          <% else %>
            <p class="mt-3 text-sm font-medium text-foreground">No programme assigned</p>
            <p class="mt-1 text-sm text-dim">Your trainer will assign a programme soon.</p>
          <% end %>
        </div>
      </div>

      <!-- Exercise Progress Section -->
      <div class="mt-10 border-t border-line pt-6">
        <div class="flex items-baseline justify-between gap-3">
          <h2 class="text-sm font-semibold text-foreground">Exercise Progress</h2>
          <span class="num text-xs text-dim">
            <%= length(@exercise_progress) %> of <%= length(@all_exercise_progress) %>
          </span>
        </div>

        <%!-- One search box instead of a muscle-chip row, matching the exercise
              library. Search covers the muscle name, so the chips were redundant. --%>
        <form phx-change="searchProgress" phx-debounce="250" class="mt-4">
          <input
            type="search"
            name="q"
            value={@progress_query}
            placeholder="Search exercises or muscle groups"
            aria-label="Search your exercises"
            class="w-full rounded-md border-line bg-muted px-4 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
          />
        </form>

        <div
          :if={@exercise_progress == []}
          class="mt-4 rounded-xl border border-dashed border-line px-6 py-12 text-center"
        >
          <p class="text-sm font-medium text-foreground">
            <%= if @all_exercise_progress == [], do: "No exercises tracked yet", else: "No matches" %>
          </p>
          <p class="mx-auto mt-1 max-w-sm text-sm text-dim">
            <%= if @all_exercise_progress == [] do %>
              Log a workout and your tracked lifts will appear here.
            <% else %>
              Try a different name or muscle group.
            <% end %>
          </p>
        </div>

        <div :if={@exercise_progress != []} class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <.link
            :for={exercise <- @exercise_progress}
            navigate={~p"/client/strengthProgress/#{exercise.exercise_id}"}
            class="group flex flex-col rounded-xl border border-line bg-card p-5 transition hover:border-dim"
          >
            <h3 class="font-semibold leading-snug text-foreground"><%= exercise.name %></h3>
            <div class="mt-3 flex flex-wrap gap-2">
              <span
                :if={exercise.muscle_name}
                class="num inline-flex items-center rounded-full border border-line px-2.5 py-1 text-xs text-dim"
              >
                <%= exercise.muscle_name %>
              </span>
              <span class="num inline-flex items-center rounded-full border border-line px-2.5 py-1 text-xs text-dim">
                <%= exercise.total_sets %> sets
              </span>
            </div>
          </.link>
        </div>
      </div>

    </div>
    """
  end

  defp get_user_initials(client) do
    case Repo.preload(client, :user) do
      %{user: %{name: name}} when not is_nil(name) ->
        name
        |> String.split(" ")
        |> Enum.take(2)
        |> Enum.map(&String.first/1)
        |> Enum.join("")
        |> String.upcase()

      _ ->
        "U"
    end
  end

end
