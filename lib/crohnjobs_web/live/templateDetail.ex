defmodule CrohnjobsWeb.TemplateDetail do

  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes.ProgrammeDetails
  alias Crohnjobs.Repo
  import Ecto.Query

  def mount(params, session, socket) do
    template_id = params["template_id"]
    programmeDetails =
      Repo.all(
        from pd in ProgrammeDetails,
          where: pd.programme_template_id == ^template_id,
          preload: [:exercise]
      )
      {:ok, assign(socket, programmeDetails: programmeDetails)}

  end

  def render(assigns) do
    ~H"""
    <h1> Hello There
    </h1>
    <%=for programmeDetail <-@programmeDetails do %>
    <%= programmeDetail.exercise.name%>
    <%end%>

    """

  end

end
