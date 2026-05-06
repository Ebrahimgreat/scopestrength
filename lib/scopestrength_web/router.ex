defmodule ScopestrengthWeb.Router do

  use ScopestrengthWeb, :router

  import ScopestrengthWeb.UserAuth
  import Oban.Web.Router

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



  scope "/admin", ScopestrengthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin_session,
      on_mount: [
        {ScopestrengthWeb.UserAuth, :ensure_authenticated},
        {ScopestrengthWeb.RequireRole, "admin"}
      ],
      layout: {ScopestrengthWeb.Layouts, :admin}
       do
      live "/", Admin.Dashboard
    end
  end


  scope "/client", ScopestrengthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :client_session,
      on_mount: [
        {ScopestrengthWeb.UserAuth, :ensure_authenticated},
        {ScopestrengthWeb.RequireRole, "client"},
        ScopestrengthWeb.RequireSubscription  # Checks trainer's subscription
      ],
      layout: {ScopestrengthWeb.Layouts, :client} do
      live "/", ClientDashboard
      live "/chat", ClientChat
      live "/notifications",Client.Notifications
      live "/weight", Client.Weight
      live "/marketplace",Client.Marketplace
      live "/marketplace/:trainer_id",Client.Marketplacetrainer
      live "/workouts", Client.Workouts
      live "/volumeTracking/:contribution",Client.MuscleContribution
      live "/workouts/:id",Client.WorkoutShow
      live "/strengthProgress/:exercise_id",Client.StrengthProgress
      live "/volumeTracking",Client.VolumeTracking
      live "/exercises", Exercises
      live "/settings", Client.ClientSettings
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
        ScopestrengthWeb.RequireSubscription  # Checks own subscription
      ],
      layout: {ScopestrengthWeb.Layouts, :trainer} do
      live "/chat", TrainerChat
      live "/invites", Invites
      live "/clients", Clients
      live "/clients/:id", ShowClient
      live "/clients/:id/notes", ClientNotes
      live "/requests",Clientrequests
      live "/clients/:id/workouts", Workouts
      live "/clients/:id/strengthProgress/:exercise_id", ExerciseProgress
      live "/clients/:id/volumeTracking", VolumeTracking
      live "/clients/:id/volumeTracking/:contribution",MuscleContribution
      live "/clients/:id/progress-photos", ClientProgressPhotos
      live "/exercises", Exercises
      live "/exercises/contribution",ExerciseVolume
      live "/notifications",Notifications
      live "/clients/:id/workouts",Workouts
      live "/clients/:id/workouts/:workout_id", WorkoutDetail
      live "/client/:id/programme", ChangeProgramme
      live "/programmes", Programmes
      live "/programmes/:id", ProgrammeShow
      live "/programmes/:id/template/:template_id", Template
      live "/programmes/:id/template/:template_id/details", TemplateDetail
      live "/", Dashboard
      live "/settings",UserSettingsLive
    end

    oban_dashboard("/oban")
  end




  # Other scopes may use custom stacks.
  # scope "/api", ScopestrengthWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:scopestrength, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ScopestrengthWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ScopestrengthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{ScopestrengthWeb.UserAuth, :ensure_authenticated}] do
      live "/chat/:room", Chat
      live "/upgrade", UpgradeLive
      live "/trainer-subscription-expired", Client.TrainerSubscriptionExpired

      get "/download/workout", DownloadController, :workout
      get "/download/client-report/:client_id", DownloadController, :client_report
    end
  end

  scope "/", ScopestrengthWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ScopestrengthWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/", UserLoginLive, :new
      # Registration disabled — demo accounts are generated via /demo
      # live "/users/register", UserRegistrationLive, :new
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

  # Catch-all: redirect unknown routes to login with a flash message
  scope "/", ScopestrengthWeb do
    pipe_through [:browser]

    get "/*path", PageController, :not_found
  end
end
