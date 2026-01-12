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
   <div class="min-h-screen bg-gradient-to-br from-slate-50 via-indigo-50 to-purple-100">
     <!-- Hero Section -->
     <div class="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 text-white">
       <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
         <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center space-y-6 lg:space-y-0">
           <div class="flex-1">
             <div class="flex items-center space-x-3 mb-4">
               <div class="w-12 h-12 bg-white bg-opacity-20 rounded-xl flex items-center justify-center">
                 <span class="text-2xl">🏋️</span>
               </div>
               <div>
                 <h1 class="text-4xl font-bold tracking-tight">Programme Management</h1>
                 <p class="text-indigo-100 mt-1">Design and manage your workout templates</p>
               </div>
             </div>
           </div>

           <div class="flex flex-col sm:flex-row space-y-3 sm:space-y-0 sm:space-x-3">
             <.button
               phx-click="addTemplate"
               class="bg-white bg-opacity-20 hover:bg-opacity-30 backdrop-blur-sm text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300 flex items-center justify-center space-x-2"
             >
               <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                 <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
               </svg>
               <span>Add Template</span>
             </.button>

             <%= if @report == false do %>
               <.button
                 phx-click="downloadProgramme"
                 class="bg-emerald-500 hover:bg-emerald-600 text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300 flex items-center justify-center space-x-2"
               >
                 <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                 </svg>
                 <span>Generate Report</span>
               </.button>
             <% end %>
           </div>
         </div>

         <%= if @report == true do %>
           <div class="mt-8 p-6 bg-white bg-opacity-20 backdrop-blur-sm rounded-2xl border border-white border-opacity-30">
             <div class="flex items-center space-x-4">
               <div class="w-12 h-12 bg-emerald-500 rounded-full flex items-center justify-center">
                 <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                 </svg>
               </div>
               <div class="flex-1">
                 <h3 class="text-lg font-semibold text-white">Report Generated Successfully!</h3>
                 <p class="text-indigo-100">Your programme report is ready for download</p>
               </div>
               <a
                 class="bg-emerald-500 hover:bg-emerald-600 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center space-x-2 font-semibold transform hover:scale-105"
                 href="/download/workout"
               >
                 <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m-3-4H7a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-3"/>
                 </svg>
                 <span>Download Now</span>
               </a>
             </div>
           </div>
         <% end %>
       </div>
     </div>

     <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 -mt-6 pb-12 space-y-8">
       <!-- Programme Details Form -->
       <div class="bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden transform hover:shadow-2xl transition-all duration-300">
         <div class="bg-gradient-to-r from-blue-500 to-purple-600 p-6 text-white">
           <div class="flex items-center space-x-3">
             <div class="w-10 h-10 bg-white bg-opacity-20 rounded-lg flex items-center justify-center">
               <span class="text-lg">📋</span>
             </div>
             <div>
               <h2 class="text-xl font-semibold">Programme Details</h2>
               <p class="text-blue-100 text-sm">Configure your programme information</p>
             </div>
           </div>
         </div>

         <div class="p-8">
           <.form phx-change="updateForm" for={@programme} class="space-y-6">
             <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
               <div class="space-y-2">
                 <label class="block text-sm font-bold text-gray-700 flex items-center space-x-2">
                   <span class="text-blue-500">🏷️</span>
                   <span>Programme Name</span>
                 </label>
                 <.input
                   field={@programme[:name]}
                   type="text"
                   class="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:ring-4 focus:ring-blue-100 transition-all duration-200 font-medium"
                   placeholder="Enter programme name..."
                 />
               </div>

               <div class="space-y-2">
                 <label class="block text-sm font-bold text-gray-700 flex items-center space-x-2">
                   <span class="text-purple-500">📝</span>
                   <span>Description</span>
                 </label>
                 <.input
                   field={@programme[:description]}
                   type="textarea"
                   class="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-purple-500 focus:ring-4 focus:ring-purple-100 transition-all duration-200 font-medium"
                   placeholder="Describe your programme..."
                   rows="3"
                 />
               </div>
             </div>
           </.form>
         </div>
       </div>

       <!-- Templates Section -->
       <div class="bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden transform hover:shadow-2xl transition-all duration-300">
         <div class="bg-gradient-to-r from-emerald-500 to-teal-600 p-6 text-white">
           <div class="flex items-center justify-between">
             <div class="flex items-center space-x-3">
               <div class="w-10 h-10 bg-white bg-opacity-20 rounded-lg flex items-center justify-center">
                 <span class="text-lg">📊</span>
               </div>
               <div>
                 <h2 class="text-xl font-semibold">Workout Templates</h2>
                 <p class="text-emerald-100 text-sm">Manage your workout templates</p>
               </div>
             </div>

             <div class="flex items-center space-x-3">
               <div class="bg-white bg-opacity-20 px-4 py-2 rounded-full">
                 <span class="text-sm font-bold">
                   <%= length(@programme.data.programmeTemplates) %> template<%= if length(@programme.data.programmeTemplates) != 1, do: "s" %>
                 </span>
               </div>
             </div>
           </div>
         </div>

         <div class="overflow-hidden">
           <%= if length(@programme.data.programmeTemplates) > 0 do %>
             <div class="overflow-x-auto">
               <table class="min-w-full">
                 <thead class="bg-gradient-to-r from-gray-50 to-gray-100">
                   <tr>
                     <th class="px-8 py-4 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">
                       <div class="flex items-center space-x-2">
                         <span class="text-blue-500">🎯</span>
                         <span>Template Name</span>
                       </div>
                     </th>
                     <th class="px-8 py-4 text-right text-xs font-bold text-gray-600 uppercase tracking-wider">
                       <div class="flex items-center justify-end space-x-2">
                         <span>Actions</span>
                         <span class="text-purple-500">⚡</span>
                       </div>
                     </th>
                   </tr>
                 </thead>
                 <tbody class="bg-white divide-y divide-gray-100">
                   <%= for template <- @programme.data.programmeTemplates do %>
                     <tr class="hover:bg-gradient-to-r hover:from-blue-50 hover:to-purple-50 transition-all duration-200 transform hover:scale-[1.01] border-l-4 border-transparent hover:border-blue-400">
                       <td class="px-8 py-6 whitespace-nowrap">
                         <div class="flex items-center space-x-4">
                           <div class="w-3 h-3 bg-gradient-to-r from-emerald-400 to-green-500 rounded-full animate-pulse"></div>
                           <div class="flex items-center space-x-3">
                             <div class="w-10 h-10 bg-gradient-to-r from-blue-100 to-purple-100 rounded-lg flex items-center justify-center">
                               <span class="text-blue-600 font-bold text-sm">📋</span>
                             </div>
                             <div>
                               <div class="text-lg font-bold text-gray-900 hover:text-blue-600 transition-colors">
                                 <%= template.name %>
                               </div>
                               <div class="text-sm text-gray-500">Workout Template</div>
                             </div>
                           </div>
                         </div>
                       </td>
                       <td class="px-8 py-6 whitespace-nowrap text-right">
                         <div class="flex items-center justify-end space-x-3">
                           <.link
                             navigate={~p"/traine/programmes/#{@programmeId}/template/#{template.id}"}
                             class="group bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white px-4 py-2 rounded-lg font-semibold shadow-md hover:shadow-lg transform hover:scale-105 transition-all duration-200 flex items-center space-x-2"
                           >
                             <svg class="w-4 h-4 group-hover:animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                               <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                               <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                             </svg>
                             <span>View</span>
                           </.link>

                           <.button
                             phx-click="deleteTemplate"
                             phx-value-id={template.id}
                             data-confirm="Are you sure you want to delete this template?"
                             class="group bg-gradient-to-r from-red-500 to-pink-600 hover:from-red-600 hover:to-pink-700 text-white px-4 py-2 rounded-lg font-semibold shadow-md hover:shadow-lg transform hover:scale-105 transition-all duration-200 flex items-center space-x-2"
                           >
                             <svg class="w-4 h-4 group-hover:animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                               <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                             </svg>
                             <span>Delete</span>
                           </.button>
                         </div>
                       </td>
                     </tr>
                   <% end %>
                 </tbody>
               </table>
             </div>
           <% else %>
             <!-- Enhanced Empty State -->
             <div class="text-center py-20 px-8">
               <div class="mx-auto w-24 h-24 bg-gradient-to-br from-indigo-100 to-purple-200 rounded-full flex items-center justify-center mb-8 animate-pulse">
                 <span class="text-4xl">📋</span>
               </div>

               <h3 class="text-2xl font-bold text-gray-900 mb-3">No Templates Yet</h3>
               <p class="text-gray-600 mb-8 max-w-md mx-auto text-lg leading-relaxed">
                 Ready to create your first workout template? Templates help you organize exercises into structured workouts.
               </p>

               <div class="space-y-4">
                 <.button
                   phx-click="addTemplate"
                   class="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-bold px-8 py-4 rounded-xl shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300 flex items-center justify-center space-x-3 mx-auto"
                 >
                   <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                     <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                   </svg>
                   <span class="text-lg">Create Your First Template</span>
                 </.button>

                 <div class="flex items-center justify-center space-x-8 text-sm text-gray-500 mt-6">
                   <div class="flex items-center space-x-2">
                     <span class="w-2 h-2 bg-green-400 rounded-full"></span>
                     <span>Easy to create</span>
                   </div>
                   <div class="flex items-center space-x-2">
                     <span class="w-2 h-2 bg-blue-400 rounded-full"></span>
                     <span>Customize exercises</span>
                   </div>
                   <div class="flex items-center space-x-2">
                     <span class="w-2 h-2 bg-purple-400 rounded-full"></span>
                     <span>Track progress</span>
                   </div>
                 </div>
               </div>
             </div>
           <% end %>
         </div>
       </div>
     </div>
   </div>
   """
  end

  end
