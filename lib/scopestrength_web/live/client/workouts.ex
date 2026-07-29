defmodule ScopestrengthWeb.Client.Workouts do
  alias Scopestrength.Training
  alias Scopestrength.Repo
  alias Scopestrength.Clients.Client
  alias Scopestrength.Training.Workout
  alias Scopestrength.Notifications
  import Ecto.Query
  use ScopestrengthWeb, :live_view

  @per_page 12
  @visible_tags 4

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, user_id: user.id)
    workouts =
      Repo.all(from w in Workout, where: w.client_id == ^client.id, order_by: [desc: w.date])
      |> Repo.preload(workoutDetails: :exercise)

    {:ok,
     socket
     |> assign(:all_workouts, workouts)
     |> assign(:page, 1)
     |> assign(:expanded, nil)
     |> paginate()}
  end

  defp paginate(socket) do
    all = socket.assigns.all_workouts
    total_pages = max(ceil(length(all) / @per_page), 1)
    page = min(socket.assigns.page, total_pages)

    workouts =
      all
      |> Enum.drop((page - 1) * @per_page)
      |> Enum.take(@per_page)
      |> Enum.map(&summarize/1)

    socket
    |> assign(:workouts, workouts)
    |> assign(:page, page)
    |> assign(:total_pages, total_pages)
  end

  # Derives the card's display data once per workout rather than recomputing it
  # inside the template. A freshly created workout has no details loaded, so
  # treat a missing association as empty rather than crashing.
  defp summarize(workout) do
    details = loaded_details(workout)

    names =
      details
      |> Enum.map(fn d -> d.exercise && d.exercise.name end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    volume =
      details
      |> Enum.map(fn d -> (d.reps || 0.0) * (d.weight || 0.0) end)
      |> Enum.sum()

    %{
      id: workout.id,
      name: workout.name,
      date: workout.date,
      exercise_names: names,
      hidden_count: max(length(names) - @visible_tags, 0),
      set_count: length(details),
      volume: volume
    }
  end

  # Cards sit in a grid, so an 8-exercise leg day would otherwise stretch its
  # row far taller than its neighbours. Cap the tags and let the card expand
  # on demand instead.
  defp visible_names(workout, expanded_id) do
    if expanded_id == workout.id do
      workout.exercise_names
    else
      Enum.take(workout.exercise_names, @visible_tags)
    end
  end

  defp loaded_details(%{workoutDetails: %Ecto.Association.NotLoaded{}}), do: []
  defp loaded_details(%{workoutDetails: details}) when is_list(details), do: details
  defp loaded_details(_), do: []

  # Volume reads better abbreviated once it runs to five digits.
  defp format_volume(volume) when volume >= 1000 do
    "#{Float.round(volume / 1000, 1)}k"
  end

  defp format_volume(volume), do: round(volume)

  def handle_event("expand", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, assign(socket, :expanded, if(socket.assigns.expanded == id, do: nil, else: id))}
  end

  def handle_event("page", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> assign(:expanded, nil)
     |> paginate()}
  end

  def handle_event("createWorkout", _params, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, user_id: user.id)
    result =
      Repo.transaction(fn ->
        case Training.create_workout(%{
               client_id: client.id,
               name: "Untitled",
               date: DateTime.utc_now()
             }) do
          {:ok, workout} ->
            if client.trainer_id do
              case Notifications.create_notification(%{
                     actor_id: user.id,
                     actor_type: "client",
                     recipient_id: client.trainer_id,
                     recipient_type: "trainer",
                     type: "workout_created",
                     data: %{workout_id: workout.id, client_id: client.id}
                   }) do
                {:ok, notification} -> {workout, notification}
                {:error, changeset} -> Repo.rollback(changeset)
              end
            else
              {workout, nil}
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, {workout, notification}} ->
        if notification do
          Phoenix.PubSub.broadcast(
            Scopestrength.PubSub,
            "notifications:trainer:#{client.trainer_id}",
            {:notification, notification}
          )
        end

        {:noreply,
         socket
         |> assign(:all_workouts, [workout | socket.assigns.all_workouts])
         |> paginate()}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Unable To create workout")}
    end
  end
  def handle_event("deleteWorkout", %{"id"=>id}, socket) do
    id= String.to_integer(id)
    workout= Training.get_workout!(id)
    case Training.delete_workout(workout) do
      {:ok, _deleted}->
        all_workouts = Enum.reject(socket.assigns.all_workouts, &(&1.id == id))
        {:noreply, socket |> assign(:all_workouts, all_workouts) |> paginate()}
        _->{:noreply,socket|>put_flash(:error, "Cannot delete")}

    end


  end



  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Training</p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Workouts
          </h1>
        </div>

        <.button phx-click="createWorkout" class="shrink-0">
          <span class="inline-flex items-center gap-2">
            <.icon name="hero-plus" class="h-4 w-4" /> Create workout
          </span>
        </.button>
      </div>

      <div :if={@workouts == []} class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center">
        <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          No workouts yet
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          Create a workout to start logging your sets.
        </p>
        <div class="mt-6">
          <.button phx-click="createWorkout">Create your first workout</.button>
        </div>
      </div>

      <div :if={@workouts != []} class="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div
          :for={workout <- @workouts}
          class="group relative flex flex-col rounded-xl border border-line bg-card p-5 transition hover:border-dim"
        >
          <%!-- Stretched link: the pseudo-element covers the whole card so it is
                clickable, while the delete button sits above it via z-index.
                Nesting the button inside the link would fire navigation too. --%>
          <.link
            navigate={~p"/client/workouts/#{workout.id}"}
            class="after:absolute after:inset-0 after:rounded-xl"
          >
            <h3 class="pr-8 font-semibold leading-snug text-foreground">
              {workout.name || "Untitled"}
            </h3>
          </.link>

          <p class="num mt-1 text-xs text-dim">
            {if workout.date, do: Calendar.strftime(workout.date, "%a, %b %d, %Y"), else: "No date"}
          </p>

          <div :if={workout.exercise_names != []} class="mt-3 flex flex-wrap gap-2">
            <span
              :for={name <- visible_names(workout, @expanded)}
              class="num inline-flex items-center rounded-full border border-line px-2.5 py-1 text-xs text-dim"
            >
              {name}
            </span>
            <%!-- Sits above the stretched link so it toggles instead of navigating. --%>
            <button
              :if={workout.hidden_count > 0 and @expanded != workout.id}
              type="button"
              phx-click="expand"
              phx-value-id={workout.id}
              class="num relative z-10 inline-flex items-center rounded-full border border-line px-2.5 py-1 text-xs text-faint transition hover:border-dim hover:text-foreground"
            >
              +{workout.hidden_count}
            </button>
            <button
              :if={@expanded == workout.id}
              type="button"
              phx-click="expand"
              phx-value-id={workout.id}
              class="num relative z-10 inline-flex items-center rounded-full border border-line px-2.5 py-1 text-xs text-faint transition hover:border-dim hover:text-foreground"
            >
              Less
            </button>
          </div>

          <p :if={workout.exercise_names == []} class="mt-3 text-xs text-faint">
            No exercises logged
          </p>

          <div class="mt-4 flex items-center gap-3 border-t border-line pt-3 text-xs text-dim">
            <span class="num inline-flex items-center gap-1.5">
              <.icon name="hero-squares-2x2" class="h-3.5 w-3.5 text-faint" />
              {workout.set_count} sets
            </span>
            <span :if={workout.volume > 0} class="num inline-flex items-center gap-1.5">
              <.icon name="hero-scale" class="h-3.5 w-3.5 text-faint" />
              {format_volume(workout.volume)} kg
            </span>
          </div>

          <button
            type="button"
            phx-click="deleteWorkout"
            phx-value-id={workout.id}
            data-confirm="Are you sure you want to delete this workout?"
            aria-label={"Delete #{workout.name || "workout"}"}
            class="absolute right-3 top-3 z-10 rounded-md p-1.5 text-dim opacity-0 transition hover:bg-danger/10 hover:text-danger focus:opacity-100 group-hover:opacity-100"
          >
            <.icon name="hero-trash" class="h-4 w-4" />
          </button>
        </div>
      </div>

      <div :if={@total_pages > 1} class="mt-6 flex items-center justify-center gap-1">
        <button
          phx-click="page"
          phx-value-page={@page - 1}
          disabled={@page == 1}
          class="rounded-md p-2 text-dim transition enabled:hover:bg-secondary enabled:hover:text-foreground disabled:opacity-30"
          aria-label="Previous page"
        >
          <.icon name="hero-chevron-left" class="h-4 w-4" />
        </button>

        <button
          :for={p <- max(1, @page - 2)..min(@total_pages, @page + 2)//1}
          phx-click="page"
          phx-value-page={p}
          aria-current={p == @page && "page"}
          class={[
            "num rounded-md px-3 py-1.5 text-sm font-medium transition",
            p == @page && "bg-primary text-primary-foreground",
            p != @page && "text-dim hover:bg-secondary hover:text-foreground"
          ]}
        >
          {p}
        </button>

        <button
          phx-click="page"
          phx-value-page={@page + 1}
          disabled={@page == @total_pages}
          class="rounded-md p-2 text-dim transition enabled:hover:bg-secondary enabled:hover:text-foreground disabled:opacity-30"
          aria-label="Next page"
        >
          <.icon name="hero-chevron-right" class="h-4 w-4" />
        </button>
      </div>
    </div>
    """
  end
end
