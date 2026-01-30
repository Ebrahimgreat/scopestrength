defmodule CrohnjobsWeb.ProgrammeShow do
  alias Crohnjobs.Trainers
  alias Crohnjobs.DownloadProgramme
  alias Crohnjobs.Programmes.Programme
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes

  def handle_event("deleteTemplate", params, socket) do
  id = String.to_integer(params["id"])
  programmeTemplate = Programmes.get_programme_template!(id)
  case Programmes.delete_programme_template(programmeTemplate) do
   {:ok, _template}->
  programme = %{socket.assigns.programme.data | programmeTemplates: Enum.reject(socket.assigns.programme.data.programmeTemplates, &(&1.id == id))}
  updated_form = Programmes.change_programme(programme)|> to_form()
   {:noreply, socket|> put_flash(:info, "Template Deleted")|> assign(:programme, updated_form)}
  end
  end

  def handle_event("downloadProgramme", _, socket) do
  programme =
  Repo.get!(Programme, socket.assigns.programmeId)
  |> Repo.preload(programmeTemplates: [programmeDetails: :exercise])
  DownloadProgramme.downloadProgramme(%{programme: programme})
   {:noreply, assign(socket, report: true)}
  end

  def handle_event("updateForm", params, socket) do
  target = Enum.at(params["_target"],1)
  IO.inspect(target)
  case target do
  "name" -> Programmes.update_programme(socket.assigns.programme.data, %{name: params["programme"]["name"]})
  programme = %{socket.assigns.programme.data | name: params["programme"]["name"]}
  myProgramme = Programmes.change_programme(programme)|>to_form()
   {:noreply, socket|> put_flash(:info, "Programme Name Updated")|> assign(:programme, myProgramme)}
  "description"-> Programmes.update_programme(socket.assigns.programme.data, %{description: params["programme"]["description"]})
  programme = %{socket.assigns.programme.data | description: params["programme"]["description"]}
  myProgramme = Programmes.change_programme(programme)|>to_form()
   {:noreply, socket|> put_flash(:info, "Programme Description Updated")|> assign(:programme, myProgramme)}
  _ -> {:noreply, put_flash(socket,:error, "Something Happened")}
  end
  end

  def handle_event("addTemplate", _params, socket) do
  id = socket.assigns.programme.data.id
  newTemplate = %{name: "Untitled", programme_id: id}
  programmeTemplates = socket.assigns.programme.data.programmeTemplates
  case Programmes.create_programme_template(newTemplate) do
   {:ok, template}->
  programme = %{socket.assigns.programme.data | programmeTemplates: programmeTemplates ++ [template]}
  updated_form = Programmes.change_programme(programme)|>to_form()
   {:noreply, socket|> put_flash(:info, "Template Added")|> assign(:programme, updated_form)}
  _ -> {:noreply, socket|> put_flash(:error, "An error has occured")}
  end
  end

  @spec mount(map(), any(), any()) :: {:ok, any()}
  def mount(%{"id"=>id}, session, socket) do
  user = socket.assigns.current_user
  trainer = Trainers.get_trainer_byUserId(user.id)
  case Programmes.get_programme_with_template(id) do
  nil -> {:ok, socket |> put_flash(:error, "Programme not found") |> redirect(to: "/programmes")}
  programme->
  case programme.trainer_id == trainer.id do
  true-> myProgramme = Programmes.change_programme(programme)|> to_form()
   {:ok, assign(socket, programme: myProgramme, programmeId: id, report: false)}
  false ->{:ok, socket|> put_flash(:error, "Programme not found")|>redirect(to: "/programmes")}
  end
  end
  end

  def render(assigns) do
   ~H"""
   <div class="w-full min-h-screen bg-white">
     <div class="w-full px-6 lg:px-10 pt-10 pb-6">
       <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight text-slate-900">
         Programme
       </h1>
       <p class="mt-2 text-slate-600 text-base lg:text-lg">
         Manage the programme details and templates.
       </p>

       <div class="mt-6 flex flex-wrap items-center gap-3">
         <.button phx-click="addTemplate" class="px-4 py-2 text-sm">
           Add Template
         </.button>
         <%= if @report == false do %>
           <.button phx-click="downloadProgramme" class="px-4 py-2 text-sm">
             Generate Report
           </.button>
         <% end %>
         <%= if @report == true do %>
           <a href="/download/workout" class="text-sm text-emerald-700 hover:text-emerald-800">
             Download report
           </a>
         <% end %>
       </div>
     </div>

     <div class="w-full px-6 lg:px-10 py-8 space-y-10">
       <div>
         <h2 class="text-lg font-semibold text-slate-900">Programme Details</h2>
         <p class="text-sm text-slate-600 mt-1">Update the name and description.</p>
         <.form phx-change="updateForm" for={@programme} class="mt-4 space-y-4 max-w-2xl">
           <div>
             <label class="block text-sm font-medium text-slate-700">Programme Name</label>
             <.input
               field={@programme[:name]}
               type="text"
               class="w-full px-3 py-2 border border-slate-300 rounded-md text-sm"
               placeholder="Enter programme name"
             />
           </div>
           <div>
             <label class="block text-sm font-medium text-slate-700">Description</label>
             <.input
               field={@programme[:description]}
               type="textarea"
               class="w-full px-3 py-2 border border-slate-300 rounded-md text-sm"
               placeholder="Describe your programme"
               rows="3"
             />
           </div>
         </.form>
       </div>

       <div>
         <div class="flex items-center justify-between">
           <h2 class="text-lg font-semibold text-slate-900">Workout Templates</h2>
           <span class="text-sm text-slate-500">
             <%= length(@programme.data.programmeTemplates) %> template<%= if length(@programme.data.programmeTemplates) != 1, do: "s" %>
           </span>
         </div>

         <%= if length(@programme.data.programmeTemplates) > 0 do %>
           <div class="mt-4 space-y-3">
             <%= for template <- @programme.data.programmeTemplates do %>
               <div class="flex flex-wrap items-center justify-between gap-3">
                 <div>
                   <p class="text-sm font-medium text-slate-900"><%= template.name %></p>
                   <p class="text-xs text-slate-500">Workout Template</p>
                 </div>
                 <div class="flex items-center gap-3 text-sm">
                   <.link
                     navigate={~p"/trainer/programmes/#{@programmeId}/template/#{template.id}"}
                     class="text-emerald-700 hover:text-emerald-800"
                   >
                     View
                   </.link>
                   <.button
                     phx-click="deleteTemplate"
                     phx-value-id={template.id}
                     data-confirm="Are you sure you want to delete this template?"
                     class="px-3 py-1 text-sm"
                   >
                     Delete
                   </.button>
                 </div>
               </div>
             <% end %>
           </div>
         <% else %>
           <p class="mt-3 text-sm text-slate-500">No templates yet.</p>
         <% end %>
       </div>
     </div>
   </div>
   """
  end

  end
