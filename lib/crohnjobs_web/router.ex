defmodule CrohnjobsWeb.Router do


  use CrohnjobsWeb, :router

  import CrohnjobsWeb.UserAuth
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CrohnjobsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CrohnjobsWeb do
  pipe_through [:browser, :require_authenticated_user]
  live_session :require_authenticated_user,
  on_mount: [{CrohnjobsWeb.UserAuth, :ensure_authenticated}] do



  live "/chat", Chat
  live "/clients", Clients
  live "/clients/:id", ShowClient
  live "/clients/:id/notes",ClientNotes
  live "/clients/:id/workouts",Workouts
  live "/clients/:id/strengthProgress", StrengthProgress
  live "/clients/:id/strengthProgress/:exercise_id",ExerciseProgress

  live "/clients/:id/workouts/:workout_id",WorkoutShow
  live "/clients/:id/workouts/:workout_id/details", WorkoutDetail
  live "/client/:id/programme", ChangeProgramme
  live "/programmes", Programmes
  live "/programmes/:id", ProgrammeShow
  live "/programmes/:id/template/:template_id", Template
  live "/programmes/:id/template/:template_id/details",TemplateDetail
  live "/", Dashboard
  live "/exercises",Exercises
  live "/workout", Exercise
  live "/users/settings", UserSettingsLive, :edit
  live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
  end
  get "/download/workout", DownloadController, :workout
  oban_dashboard "/oban"

  end

  # Other scopes may use custom stacks.
  # scope "/api", CrohnjobsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:crohnjobs, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CrohnjobsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", CrohnjobsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{CrohnjobsWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end


  scope "/", CrohnjobsWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{CrohnjobsWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
