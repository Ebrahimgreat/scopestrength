# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

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
      <div class="pt-safe fixed top-0 left-0 right-0 z-40 flex items-center justify-between border-b border-line bg-card px-4 py-3 md:hidden">
        <.brand label={@label} home={@home} />
        <.link
          :if={@notifications_path}
          navigate={@notifications_path}
          class="relative shrink-0 rounded-md p-1.5 text-dim transition hover:bg-secondary hover:text-foreground"
          aria-label={
            if @unread_count > 0,
              do: "Notifications, #{@unread_count} unread",
              else: "Notifications"
          }
        >
          <.icon name="hero-bell" class="h-6 w-6" />
          <span
            :if={@unread_count > 0}
            class="num absolute -right-0.5 -top-0.5 inline-flex h-4 min-w-[1rem] items-center justify-center rounded-full bg-primary px-1 text-[10px] font-bold text-primary-foreground"
          >
            {if @unread_count > 9, do: "9+", else: @unread_count}
          </span>
        </.link>
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

      <main class="flex min-w-0 flex-1 flex-col pt-14 pb-28 md:pb-0 md:pt-0">
        {render_slot(@inner_block)}
      </main>

      <.tab_bar items={@items} active_path={@active_path} drawer={@id} />
    </div>
    """
  end

  attr :items, :list, required: true
  attr :active_path, :string, default: nil
  attr :drawer, :string, required: true

  defp tab_bar(assigns) do
    assigns = assign(assigns, :tabs, Enum.take(assigns.items, 4))

    ~H"""
    <nav
      class="pb-safe fixed bottom-0 left-0 right-0 z-40 flex items-stretch border-t border-line bg-card md:hidden"
      aria-label="Primary"
    >
      <.tab_link :for={item <- @tabs} item={item} active_path={@active_path} />
      <button
        type="button"
        onclick={"document.getElementById('#{@drawer}').classList.toggle('hidden')"}
        class="flex flex-1 flex-col items-center justify-center gap-1 py-2 text-dim transition active:bg-secondary"
        aria-label="More"
      >
        <.icon name="hero-ellipsis-horizontal" class="h-6 w-6" />
        <span class="text-[10px] font-medium leading-none">More</span>
      </button>
    </nav>
    """
  end

  attr :item, :map, required: true
  attr :active_path, :string, default: nil

  defp tab_link(assigns) do
    assigns = assign(assigns, :active, active?(assigns.item, assigns.active_path))

    ~H"""
    <.link
      navigate={@item.path}
      aria-current={@active && "page"}
      class={[
        "flex flex-1 flex-col items-center justify-center gap-1 py-2 transition active:bg-secondary",
        @active && "text-primary",
        !@active && "text-dim"
      ]}
    >
      <.icon name={@item.icon} class="h-6 w-6" />
      <span class="max-w-full truncate px-1 text-[10px] font-medium leading-none">
        {@item.label}
      </span>
    </.link>
    """
  end

  attr :label, :string, required: true
  attr :home, :string, required: true

  defp brand(assigns) do
    ~H"""
    <.link
      href={@home}
      class="inline-flex items-center gap-2 font-display text-lg font-bold uppercase tracking-wide text-foreground"
    >
      {@label}
    </.link>
    """
  end

  attr :label, :string, required: true

  attr :home, :string, required: true
  attr :role, :string, required: true
  attr :user_name, :string, default: nil
  attr :items, :list, required: true
  attr :footer_items, :list, required: true
  attr :active_path, :string, default: nil
  attr :notifications_path, :any, default: nil
  attr :unread_count, :integer, default: 0
  attr :dismiss, :any, default: nil

  defp sidebar_body(assigns) do
    ~H"""
    <div class="border-b border-line px-6 py-6">
      <div class="flex items-center justify-between">
        <.brand label={@label}  home={@home} />
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

  defp active?(_item, nil), do: false

  defp active?(%{path: path, exact: true}, current), do: path == current

  defp active?(%{path: path}, current),
    do: current == path or String.starts_with?(current, path <> "/")
end
