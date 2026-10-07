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

defmodule ScopestrengthWeb.Router do

  use ScopestrengthWeb, :router

  import ScopestrengthWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ScopestrengthWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    # Rate limit before authenticating, so token guessing is capped too.
    plug ScopestrengthWeb.Plugs.ApiRateLimit
    plug ScopestrengthWeb.Plugs.ApiAuth
  end

  # MCP (Model Context Protocol) endpoint, so an assistant such as Claude can
  # read the programme and log workouts. claude.ai connectors cannot send
  # custom headers, so the token may ride in the path; a bearer header works
  # too. Same tokens, same rate limit, same one-client scoping as /api.
  pipeline :mcp do
    plug ScopestrengthWeb.Plugs.ApiRateLimit
    plug ScopestrengthWeb.Plugs.McpAuth
  end

  # Pipelines apply per scope, so the routes that change data live in their own
  # scope with this extra check rather than alongside the reads.
  pipeline :api_write do
    plug ScopestrengthWeb.Plugs.RequireWriteScope
  end

  # Read-only API over the API user's own training data. Every action scopes to
  # the client resolved from the bearer token, so no route takes a client id.
  scope "/api", ScopestrengthWeb.Api do
    pipe_through [:api, :api_auth]

    get "/me/summary", ClientController, :summary
    get "/me/workouts", ClientController, :workouts
    get "/me/exercises", ClientController, :exercises
    get "/me/progressions/:exercise_id", ClientController, :progressions
  end

  # Same auth, plus a scope check: a read-only token must not create or delete.
  scope "/api", ScopestrengthWeb.Api do
    pipe_through [:api, :api_auth, :api_write]

    post "/me/workouts", ClientController, :create_workout
    delete "/me/workouts/:id", ClientController, :delete_workout
  end

  scope "/mcp", ScopestrengthWeb do
    pipe_through :mcp

    post "/", McpController, :handle
    get "/", McpController, :method_not_allowed
    post "/:token", McpController, :handle
    get "/:token", McpController, :method_not_allowed
    delete "/:token", McpController, :method_not_allowed
  end



  scope "/client", ScopestrengthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :client_session,
      on_mount: [
        {ScopestrengthWeb.UserAuth, :ensure_authenticated},
        {ScopestrengthWeb.RequireRole, "client"},
        ScopestrengthWeb.ActivePath,
        ScopestrengthWeb.UnreadNotifications
      ],
      layout: {ScopestrengthWeb.Layouts, :client} do
      live "/", ClientDashboard
      live "/chat", ClientChat
      live "/notifications",Client.Notifications
      live "/weight", Client.Weight
      live "/workouts", Client.Workouts
      live "/volumeTracking/:contribution",Client.MuscleContribution
      live "/workouts/:id",Client.WorkoutShow
      live "/strengthProgress/:exercise_id",Client.StrengthProgress
      live "/volumeTracking",Client.VolumeTracking
      live "/exercises", Exercises
      live "/settings", Client.ClientSettings
      live "/settings/api-tokens", Client.ApiTokens
      live "/progress-photos", Client.ProgressPhotos
      live "/programmes", Client.Programmes
      live "/programmes/:id", Client.ProgrammeShow
      live "/programmes/:id/template/:template_id", Client.Template
      live "/programmes/:id/template/:template_id/details", Client.TemplateDetail
    end
  end


  scope "/trainer", ScopestrengthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :trainer_session,
      on_mount: [
        {ScopestrengthWeb.UserAuth, :ensure_authenticated},
        {ScopestrengthWeb.RequireRole, "trainer"},
        ScopestrengthWeb.ActivePath,
        ScopestrengthWeb.UnreadNotifications
      ],
      layout: {ScopestrengthWeb.Layouts, :trainer} do
      live "/chat", TrainerChat
      live "/invites", Invites
      live "/clients", Clients
      live "/clients/:id", ShowClient
      live "/clients/:id/notes", ClientNotes
      live "/clients/:id/strengthProgress/:exercise_id", ExerciseProgress
      live "/clients/:id/volumeTracking", VolumeTracking
      live "/clients/:id/volumeTracking/:contribution",MuscleContribution
      live "/clients/:id/progress-photos", ClientProgressPhotos
      live "/exercises", Exercises
      live "/exercises/contribution",ExerciseVolume
      live "/notifications",Notifications
      live "/clients/:id/workouts",Workouts
      live "/clients/:id/workouts/:workout_id", WorkoutDetail
      live "/programmes", Programmes
      live "/programmes/:id", ProgrammeShow
      live "/programmes/:id/template/:template_id", Template
      live "/programmes/:id/template/:template_id/details", TemplateDetail
      live "/", Dashboard
      live "/settings",UserSettingsLive
    end
  end





  if Application.compile_env(:scopestrength, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ScopestrengthWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end


  scope "/", ScopestrengthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{ScopestrengthWeb.UserAuth, :ensure_authenticated}] do
      live "/chat/:room", Chat

      get "/download/workout", DownloadController, :workout
      get "/download/client-report/:client_id", DownloadController, :client_report
    end
  end

  scope "/", ScopestrengthWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ScopestrengthWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/", UserLoginLive, :new
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
    post "/demo", DemoController, :create
  end

  scope "/", ScopestrengthWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ScopestrengthWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/", ScopestrengthWeb do
    pipe_through [:browser]

    get "/*path", PageController, :not_found
  end
end
