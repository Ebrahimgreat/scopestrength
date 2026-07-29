defmodule ScopestrengthWeb.Sidebar do
  @moduledoc """
  Shared app shell: dark sidebar + main column.

  The client, trainer and admin layouts were three near-identical copies of the
  same markup, each duplicated again for mobile and desktop. They now all render
  `app_shell/1` and differ only in the nav items passed to it.
  """
  use Phoenix.Component
  import ScopestrengthWeb.CoreComponents, only: [icon: 1]

  attr :label, :string, required: true
  attr :short, :string, required: true, doc: "initials shown in the sidebar header badge"
  attr :home, :string, required: true
  attr :role, :string, required: true
  attr :user_name, :string, default: nil
  attr :active_path, :string, default: nil
  attr :id, :string, required: true
  attr :items, :list, required: true, doc: "list of %{label:, path:, icon:, badge:}"
  attr :footer_items, :list, default: []
  attr :notifications_path, :any, default: nil, doc: "omit to hide the bell"
  attr :unread_count, :integer, default: 0
  slot :inner_block, required: true

  def app_shell(assigns) do
    ~H"""
    <div class="min-h-screen flex bg-background text-foreground">
      <div class="fixed top-0 left-0 right-0 z-40 flex items-center justify-between border-b border-line bg-card px-4 py-3 md:hidden">
        <.brand label={@label} short={@short} home={@home} />
        <button
          onclick={"document.getElementById('#{@id}').classList.toggle('hidden')"}
          class="p-2 text-dim hover:text-foreground"
          aria-label="Open menu"
        >
          <.icon name="hero-bars-3" class="h-6 w-6" />
        </button>
      </div>

      <div id={@id} class="hidden fixed inset-0 z-50 md:hidden">
        <div
          onclick={"document.getElementById('#{@id}').classList.add('hidden')"}
          class="absolute inset-0 bg-black/70"
        >
        </div>
        <aside class="relative flex h-full w-72 flex-col overflow-y-auto border-r border-line bg-card">
          <.sidebar_body
            label={@label}
            short={@short}
            home={@home}
            role={@role}
            user_name={@user_name}
            items={@items}
            footer_items={@footer_items}
            active_path={@active_path}
            notifications_path={@notifications_path}
            unread_count={@unread_count}
            dismiss={@id}
          />
        </aside>
      </div>

      <aside class="sticky top-0 hidden h-screen w-72 flex-col overflow-y-auto border-r border-line bg-card md:flex">
        <.sidebar_body
          label={@label}
          short={@short}
          home={@home}
          role={@role}
          user_name={@user_name}
          items={@items}
          footer_items={@footer_items}
          active_path={@active_path}
          notifications_path={@notifications_path}
          unread_count={@unread_count}
          dismiss={nil}
        />
      </aside>

      <main class="flex min-w-0 flex-1 flex-col pt-14 md:pt-0">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :short, :string, required: true
  attr :home, :string, required: true

  defp brand(assigns) do
    ~H"""
    <.link
      href={@home}
      class="inline-flex items-center gap-2 font-display text-lg font-bold uppercase tracking-wide text-foreground"
    >
      <span class="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-xs font-bold text-primary-foreground">
        {@short}
      </span>
      {@label}
    </.link>
    """
  end

  attr :label, :string, required: true
  attr :short, :string, required: true
  attr :home, :string, required: true
  attr :role, :string, required: true
  attr :user_name, :string, default: nil
  attr :items, :list, required: true
  attr :footer_items, :list, required: true
  attr :active_path, :string, default: nil
  attr :notifications_path, :any, default: nil
  attr :unread_count, :integer, default: 0
  # nil on the desktop sidebar, which has nothing to dismiss.
  attr :dismiss, :any, default: nil

  defp sidebar_body(assigns) do
    ~H"""
    <div class="border-b border-line px-6 py-6">
      <div class="flex items-center justify-between">
        <.brand label={@label} short={@short} home={@home} />
        <button
          :if={@dismiss}
          onclick={"document.getElementById('#{@dismiss}').classList.add('hidden')"}
          class="p-1 text-dim hover:text-foreground"
          aria-label="Close menu"
        >
          <.icon name="hero-x-mark" class="h-5 w-5" />
        </button>
      </div>
      <div class="mt-4 flex items-center gap-3">
        <div class="flex h-9 w-9 items-center justify-center rounded-full bg-secondary text-sm font-bold text-primary">
          {String.first(@user_name || @role)}
        </div>
        <div class="min-w-0 flex-1">
          <p class="truncate text-sm font-medium text-foreground">{@user_name}</p>
          <p class="text-xs text-dim">{@role}</p>
        </div>

        <%!-- Unread count comes from the UnreadNotifications on_mount hook, which
              subscribes for the whole live_session so the badge survives
              navigation between pages. --%>
        <.link
          :if={@notifications_path}
          navigate={@notifications_path}
          onclick={@dismiss && "document.getElementById('#{@dismiss}').classList.add('hidden')"}
          class="relative shrink-0 rounded-md p-1.5 text-dim transition hover:bg-secondary hover:text-foreground"
          aria-label={
            if @unread_count > 0,
              do: "Notifications, #{@unread_count} unread",
              else: "Notifications"
          }
        >
          <.icon name="hero-bell" class="h-5 w-5" />
          <span
            :if={@unread_count > 0}
            class="num absolute -right-0.5 -top-0.5 inline-flex h-4 min-w-[1rem] items-center justify-center rounded-full bg-primary px-1 text-[10px] font-bold text-primary-foreground"
          >
            {if @unread_count > 9, do: "9+", else: @unread_count}
          </span>
        </.link>
      </div>
    </div>

    <nav class="flex-1 space-y-1 overflow-y-auto px-3 py-4">
      <.nav_item :for={item <- @items} item={item} active_path={@active_path} dismiss={@dismiss} />
    </nav>

    <div class="mt-auto space-y-1 border-t border-line px-3 py-4">
      <.nav_item
        :for={item <- @footer_items}
        item={item}
        active_path={@active_path}
        dismiss={@dismiss}
      />
      <.link
        href="/users/log_out"
        method="delete"
        class="group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-dim transition hover:bg-secondary hover:text-danger"
      >
        <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5 shrink-0" />
        Log out
      </.link>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :active_path, :string, default: nil
  attr :dismiss, :any, default: nil

  defp nav_item(assigns) do
    assigns = assign(assigns, :active, active?(assigns.item, assigns.active_path))

    ~H"""
    <.link
      href={@item.path}
      onclick={@dismiss && "document.getElementById('#{@dismiss}').classList.add('hidden')"}
      aria-current={@active && "page"}
      class={[
        "group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition",
        @active && "bg-primary/10 text-primary",
        !@active && "text-dim hover:bg-secondary hover:text-foreground"
      ]}
    >
      <.icon name={@item.icon} class="h-5 w-5 shrink-0" />
      <span class="flex-1 truncate">{@item.label}</span>
      <span
        :if={@item[:badge]}
        class="num inline-flex min-w-[1.25rem] items-center justify-center rounded px-1.5 py-0.5 text-xs font-bold bg-primary text-primary-foreground"
      >
        {@item.badge}
      </span>
    </.link>
    """
  end

  # The home link ("/client") is a prefix of every other path in its section, so
  # it only counts as active on an exact match. Everything else also matches its
  # own sub-routes, keeping e.g. /client/workouts/12 highlighted under Workouts.
  defp active?(_item, nil), do: false

  defp active?(%{path: path, exact: true}, current), do: path == current

  defp active?(%{path: path}, current),
    do: current == path or String.starts_with?(current, path <> "/")
end
