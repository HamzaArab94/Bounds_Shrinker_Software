using Gtk
using Gtk.ShortNames
using AmplNLReader

include("GUI_callbacks.jl")
include("./../Algorithms/ConstraintConsensus.jl")
include("./../Algorithms/GetANucleus.jl")
include("./../Algorithms/NonLinearIntervalSampling.jl")

using ConstraintConsensus
using GetANucleus
using NonLinearIntervalSampling

#Global variables
selected_model_name = ""
selected_algorithm = ""
selected_model = ""
unbounded_lower_value = -(1*10)^20
unbounded_upper_value = (1*10)^20
current_bounds = Array{Float64}
new_bounds = Array{Float64}
s_alpha = 0.5
s_beta = 0.1
s_ccpoints = 10
s_ccmaxit = 500

#=
Main function to load all GUI components
=#
function load_gui()
  global main_grid, main_window

  #Grid layout
  main_grid = Grid()

  setproperty!(main_grid, :column_spacing, 15)

  #Our menu bar
  mb = MenuBar()

  #=
  File menu option
  =#
  file = MenuItem("_File")
  filemenu = Menu(file)

  #Load model option within file
  load_ = MenuItem("Load Model")
  push!(filemenu, load_)
  id_load_model = signal_connect(load_model_clicked_callback, load_, "button-press-event")

  #Save model option within file
  save_ = MenuItem("Save")
  push!(filemenu, save_)

  #Save model option within file
  settings_ = MenuItem("Settings")
  push!(filemenu, settings_)
  id_settings = signal_connect(settings_clicked_callback, settings_, "button-press-event")

  #Exit option within file
  exit_ = MenuItem("Exit")
  push!(filemenu, exit_)
  id_exit = signal_connect(exit_clicked_callback, exit_, "button-press-event")

  #Push the file menu to the menu bar
  push!(mb, file)

  #=
  Select Algorithm menu option
  =#
  select = MenuItem("_Select Algorithm")
  selectmenu = Menu(select)
  mrc_ = MenuItem("Manual Range Cutting")
  push!(selectmenu, mrc_)
  gan_ = MenuItem("Get a Nucleus")
  push!(selectmenu, gan_)
  nrc_ = MenuItem("Nonlinear Range Cutting")
  push!(selectmenu, nrc_)
  nis_ = MenuItem("Nonlinear Interval Sampling")
  push!(selectmenu, nis_)
  cc_ = MenuItem("Constraint Consensus")
  push!(selectmenu, cc_)
  exact_ = MenuItem("Exact Solution")
  push!(selectmenu, exact_)

  id_mrc = signal_connect(select_algorithm_clicked_callback, mrc_, "button-press-event")
  id_gan = signal_connect(select_algorithm_clicked_callback, gan_, "button-press-event")
  id_nrc = signal_connect(select_algorithm_clicked_callback, nrc_, "button-press-event")
  id_nis= signal_connect(select_algorithm_clicked_callback, nis_, "button-press-event")
  id_cc = signal_connect(select_algorithm_clicked_callback, cc_, "button-press-event")
  id_exact = signal_connect(select_algorithm_clicked_callback, exact_, "button-press-event")

  #Push the file menu to the menu bar
  push!(mb, select)

  #=
  Main window creation
  =#

  #Create the main window
  main_window = Window("Bounds Shrinker", 1000, 500, true, true)

  #Add menu bar to grid layout
  main_grid[1:2, 1] = mb

  #Load our model information frame
  load_model_details_frame()

  #Load our model variables frame
  load_model_variables_frame()

  #Load our selected algorithm frame
  load_selected_algorithm_frame()

  #Push our grid items to main window
  push!(main_window, main_grid)
  showall(main_window)

end

#=
Loads the frame that displays the loaded models
details such as number of variables, constraints,
etc.
=#
function load_model_details_frame()
  global main_grid, mdf_name, mdf_variables_val, mdf_constraints1_val, mdf_constraints2_val, mdf_constraints3_val

  #Our frame for model information
  f1 = Frame("Model Information")
  setproperty!(f1, :margin, 15)

  main_grid[1,2] = f1

  #Grid layout
  g_md = Grid()
  setproperty!(g_md, :margin, 10)

  #Label for model information
  mdf_name = Label("No model selected")
  setproperty!(mdf_name, :margin, 5)
  mdf_variables = Label("# Variables:")
  setproperty!(mdf_variables, :xalign, 0)
  mdf_variables_val = Label("N/A")
  setproperty!(mdf_variables_val, :xalign, 0)
  mdf_constraints1 = Label("# General Constraints:")
  setproperty!(mdf_constraints1, :xalign, 0)
  mdf_constraints1_val = Label("N/A")
  setproperty!(mdf_constraints1_val, :xalign, 0)
  mdf_constraints2 = Label("# Linear Constraints:")
  setproperty!(mdf_constraints2, :xalign, 0)
  mdf_constraints2_val = Label("N/A")
  setproperty!(mdf_constraints2_val, :xalign, 0)
  mdf_constraints3 = Label("# Nonlinear General Constraints:")
  setproperty!(mdf_constraints3, :xalign, 0)
  mdf_constraints3_val = Label("N/A")
  setproperty!(mdf_constraints3_val, :xalign, 0)

  #Add elements to frame
  g_md[1:2, 1] = mdf_name
  g_md[1, 2] = mdf_variables
  g_md[2, 2] = mdf_variables_val
  g_md[1, 3] = mdf_constraints1
  g_md[2, 3] = mdf_constraints1_val
  g_md[1, 4] = mdf_constraints2
  g_md[2, 4] = mdf_constraints2_val
  g_md[1, 5] = mdf_constraints3
  g_md[2, 5] = mdf_constraints3_val

  #Add this sub grid to our main grid
  push!(f1, g_md)

end

#=
Loads the frame that displays the models variables
=#
function load_model_variables_frame()
  global main_grid, variable_list

  #Our frame for model information
  f2 = Frame("Model Variables")
  setproperty!(f2, :margin, 15)

  #Our actual list stored
  variable_list = ListStore(Int, Float64, Float64, Float64, Float64, String, String)

  #Viewing our list
  tv_container = ScrolledWindow()
  setproperty!(tv_container, :hexpand, true)
  tv = TreeView(TreeModel(variable_list))
  rTxt = CellRendererText()

  #Columns
  c1 = TreeViewColumn("Var", rTxt, Dict([("text",0)]))
  c2 = TreeViewColumn("Orig LB", rTxt, Dict([("text",1)]))
  c3 = TreeViewColumn("Orig UB", rTxt, Dict([("text",2)]))
  c4 = TreeViewColumn("New LB", rTxt, Dict([("text",3)]))
  c5 =  TreeViewColumn("New UB", rTxt, Dict([("text",4)]))
  c6 = TreeViewColumn("LB % Shrunk", rTxt, Dict([("text",5)]))
  c7 = TreeViewColumn("UB % Shrunk", rTxt, Dict([("text",6)]))
  push!(tv, c1, c2, c3, c4, c5, c6, c7)

  #Make the columns sortable
  for (i,c) in enumerate([c1,c2,c3,c4,c5,c6,c7])
    GAccessor.sort_column_id(c,i-1)
  end

  #Push to frame
  push!(tv_container, tv)
  push!(f2, tv_container)

  #Set frame inside grid
  main_grid[2, 2:3] = f2


end

#=
Loads the frame that displays the selected algorithm
=#
function load_selected_algorithm_frame()
  global main_grid, selected_algorithm, shrink_bounds_btn, accept_bounds_btn, saf_name
  global g_sa, f3, s_alpha_name, s_alpha_input, s_beta_name, s_beta_input, s_points_name, s_points_input, s_maxit_name, s_maxit_input, shrink_bounds_btn, accept_bounds_btn

  #Our frame for model information
  f3 = Frame("Selected Algorithm")
  setproperty!(f3, :margin, 15)

  main_grid[1, 3] = f3
  setproperty!(main_grid, :row_spacing, 5)
  setproperty!(main_grid, :column_spacing, 5)

  #Grid layout
  g_sa = Grid()
  setproperty!(g_sa, :margin, 10)

  #Labels
  saf_name = Label("No algorithm selected")
  setproperty!(saf_name, :margin, 5)
  setproperty!(saf_name, :xalign, 0.5)

  #Buttons
  shrink_bounds_btn = Button("Shrink Bounds")
  setproperty!(shrink_bounds_btn, :sensitive, false)
  id_shrink_bounds = signal_connect(shrink_bounds_clicked_callback, shrink_bounds_btn, "button-press-event")

  accept_bounds_btn = Button("Accept New Bounds")
  setproperty!(accept_bounds_btn, :sensitive, false)

  #Assign element locations
  g_sa[1:2, 1] = saf_name

  g_sa[1, 2] = shrink_bounds_btn
  g_sa[2, 2] = accept_bounds_btn

  #Assign position of the frame
  push!(f3, g_sa)

end
