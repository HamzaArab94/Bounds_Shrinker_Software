
#Callback for load model menu item
function load_model_clicked_callback(leaf, button)
  global selected_model, selected_model_name, selected_algorithm, main_window, shrink_bounds_btn

  #Allow user to select a model
  File = open_dialog("Choose a model",Null(),("*.nl",FileFilter("*.nl",name="All supported formats")))

  if(length(File) > 0)

    #Load model
    selected_model = AmplModel(File)

    #Get model name
    selected_model_name = basename(File)

    #Update the variable list with the newly selected models variables
    update_variable_list(false)

    #Update model information
    update_model_details()

    #If the algorithm has been selected, we are ready to shrink
    if selected_algorithm != ""

      println("Selected algorithm is $selected_algorithm")

      #Get a nucleus requires 1 unbounded variable
      if selected_algorithm == "Get a Nucleus" && selected_model_has_unbounded() == false
        setproperty!(shrink_bounds_btn, :sensitive, false)
        warn_dialog("Get a Nucleus requires the model to have at least 1 unbounded variable", main_window)

      else
        setproperty!(shrink_bounds_btn, :sensitive, true)
      end
    end

  else

    println("No file chosen")

  end

end

#Check whether or not the selected model has at least 1 unbounded variable
function selected_model_has_unbounded()
  global selected_model


  #loop each variable
  counter = 1
  while counter <= selected_model.meta.nvar

    #If lower bound is unbounded return true
    if selected_model.meta.lvar[counter] == Inf
      return true
    end

    #If upper bound is unbounded return true
    if selected_model.meta.uvar[counter] == Inf
      return true
    end

    #Check next variable
    counter = counter + 1
  end

  #If we get here there are no unbounded variables
  return false

end

#Callback for when exit is clicked
function exit_clicked_callback(leaf, button)
  println("exit")
  quit()
end

#Callback for when shrink bounds is clicked
function shrink_bounds_clicked_callback(leaf, button)
  global selected_model, selected_algorithm, new_bounds
  global s_alpha, s_beta, s_ccpoints, s_ccmaxit, accept_bounds_btn
  global s_min_points, s_max_points, s_point_every_x

  #if the model has been specified
  if selected_model != "" && selected_algorithm != ""

    #Initialize new bounds array
    new_bounds = Array{Float64}(selected_model.meta.nvar, 2)

    if selected_algorithm == "Manual Range Cutting"

    elseif selected_algorithm == "Get a Nucleus"

      #Specify settings for get a nucleus and run
      GetANucleus.set_unbounded_lower_value(unbounded_lower_value)
      GetANucleus.set_unbounded_upper_value(unbounded_upper_value)
      GetANucleus.run(selected_model, new_bounds)

    elseif selected_algorithm == "Nonlinear Range Cutting"

      #Specify settings for nonlinear interval sampling and run
      NonLinearRangeCutting.set_unbounded_lower_value(unbounded_lower_value)
      NonLinearRangeCutting.set_unbounded_upper_value(unbounded_upper_value)
      NonLinearRangeCutting.set_max_random_points(s_max_points)
      NonLinearRangeCutting.set_min_random_points(s_min_points)
      NonLinearRangeCutting.set_point_every_x(s_point_every_x)
      NonLinearRangeCutting.run(selected_model, new_bounds)

    elseif selected_algorithm == "Nonlinear Interval Sampling"

      #Specify settings for nonlinear interval sampling and run
      NonLinearIntervalSampling.set_unbounded_lower_value(unbounded_lower_value)
      NonLinearIntervalSampling.set_unbounded_upper_value(unbounded_upper_value)
      NonLinearIntervalSampling.run(selected_model, new_bounds)

    elseif selected_algorithm == "Constraint Consensus"

      #Specify settings for constraint consensus and run
      ConstraintConsensus.set_unbounded_lower_value(unbounded_lower_value)
      ConstraintConsensus.set_unbounded_upper_value(unbounded_upper_value)
      ConstraintConsensus.set_alpha(s_alpha)
      ConstraintConsensus.set_beta(s_beta)
      ConstraintConsensus.set_points_to_generate(s_ccpoints)
      ConstraintConsensus.set_max_iterations(s_ccmaxit)
      ConstraintConsensus.run(selected_model, new_bounds)

    elseif selected_algorithm == "Exact Solution"

    end

    #Enable the accept new variable bounds button
    setproperty!(accept_bounds_btn, :sensitive, true)

    #Update the variable list after the algorithm has run
    update_variable_list(true)


  else

    if isempty(selected_model)
      println("selected model is empty")
    end

    if isempty(selected_algorithm)
      println("selected algorithm is empty")
    end

  end

end

#Callback for when the user clicks accept bounds
function accept_bounds_clicked_callback(leaf, button)
  global new_bounds, selected_model, accept_bounds_btn

  println("accept bounds clicked")

  #loop each variable
  counter = 1
  while counter <= selected_model.meta.nvar

    #Set the models upper and lower bound for variable to new values
    selected_model.meta.lvar[counter] = new_bounds[counter, 1]
    selected_model.meta.uvar[counter] = new_bounds[counter, 2]

    #Increment counter
    counter = counter + 1

  end

  #Reset the new bounds array as they have been moved to actual bounds
  new_bounds = Array{Float64}

  #Disable the accept new bounds button
  setproperty!(accept_bounds_btn, :sensitive, true)

  #Update the variable list
  update_variable_list(false)


end

#Callback for when alorithm selected
function select_algorithm_clicked_callback(leaf, button)
  global selected_algorithm, shrink_bounds_btn, selected_model, saf_name, main_window

  selected_algorithm = getproperty(leaf, :label, String)
  setproperty!(saf_name, :label, selected_algorithm)

  #if the model is not empty, we are ready to shrink
  if selected_model != ""

    #Get a nucleus requires 1 unbounded variable
    if selected_algorithm == "Get a Nucleus" && selected_model_has_unbounded() == false
      warn_dialog("Get a Nucleus requires the model to have at least 1 unbounded variable", main_window)
      setproperty!(shrink_bounds_btn, :sensitive, false)

    #Not get a nucleus or the model has 1 unbounded variable
    else
      setproperty!(shrink_bounds_btn, :sensitive, true)
    end

  end

end

#Update the variable list based on the selected model
function update_variable_list(include_new_bounds)
  global selected_model, variable_list, current_bounds, new_bounds

  empty!(variable_list)

  #Variables for model
  current_bounds = Array{Float64}(selected_model.meta.nvar, 2)

  #Save variables in list
  counter = 1

  #Update the current bounds in the table
  while counter <= selected_model.meta.nvar

    #Current bounds
    current_lower = selected_model.meta.lvar[counter]
    current_upper = selected_model.meta.uvar[counter]
    current_bounds[counter, 1] = current_lower
    current_bounds[counter, 2] = current_upper

    #New bounds
    if include_new_bounds

      new_lower = round(new_bounds[counter, 1], 5)
      new_upper = round(new_bounds[counter, 2], 5)

      percent_change_lower_val = ((current_lower - new_lower) / current_lower) * 100
      if percent_change_lower_val < 0.01
        percent_change_lower_val = 0
      end

      percent_change_upper_val = ((current_upper - new_upper) / current_upper) * 100
      if percent_change_upper_val < 0.01
        percent_change_upper_val = 0
      end

      percent_change_lower = "$percent_change_lower_val%"
      percent_change_upper = "$percent_change_upper_val%"

    else
      new_lower = 0.00
      new_upper = 0.00

      percent_change_lower = "N/A"
      percent_change_upper = "N/A"
    end

    println("New lower is $new_lower")
    println("New upper is $new_upper")

    push!(variable_list, (counter, current_lower, current_upper, new_lower, new_upper, percent_change_lower, percent_change_upper))

    counter = counter + 1

    #Added to prevent crashing when loading a big model
    if counter > 100
      break
    end

  end

end

#Updates the model information
function update_model_details()
  global selected_model, selected_model_name
  global mdf_name, mdf_variables_val, mdf_constraints1_val, mdf_constraints2_val, mdf_constraints3_val

  #Update values
  setproperty!(mdf_name, :label, selected_model_name)
  setproperty!(mdf_variables_val, :label, selected_model.meta.nvar)
  setproperty!(mdf_constraints1_val, :label, selected_model.meta.ncon)
  setproperty!(mdf_constraints2_val, :label, selected_model.meta.nlin)
  setproperty!(mdf_constraints3_val, :label, selected_model.meta.nnln)

end

#Open the algorithm settings window
function settings_clicked_callback(leaf, button)

  global unbounded_lower_value, unbounded_upper_value, s_alpha, s_beta, s_ccpoints, s_ccmaxit
  global s_ulv_input, s_uuv_input, s_alpha_input, s_beta_input, s_ccpoints_input, s_ccmaxit_input, settings_window
  global s_max_points_input, s_min_points_input, s_point_every_x_input
  global s_max_points, s_min_points, s_point_every_x

  settings_window = Window("Algorithm Settings", 400, 450, true, true)

  #Grid layout
  settings_grid = Grid()

  #Our frame for model information
  f1 = Frame("General Settings")
  setproperty!(f1, :margin, 15)

  #Grid for general settings
  g_md = Grid()
  setproperty!(g_md, :margin, 10)
  setproperty!(g_md, :column_spacing, 15)

  #Settings for Constraint Consensus
  s_ulv_name = Label("Unbounded Lower Value")
  s_ulv_input = Entry()
  setproperty!(s_ulv_input, :text, unbounded_lower_value)

  s_uuv_name = Label("Unbounded Upper Value")
  s_uuv_input = Entry()
  setproperty!(s_uuv_input, :text, unbounded_upper_value)

  g_md[1, 1] = s_ulv_name
  g_md[2, 1] = s_ulv_input
  g_md[1, 2] = s_uuv_name
  g_md[2, 2] = s_uuv_input

  push!(f1, g_md)

  #Our frame for model information
  f2 = Frame("Constraint Consensus")
  setproperty!(f2, :margin, 15)

  #Grid for general settings
  g_md2 = Grid()
  setproperty!(g_md2, :margin, 10)
  setproperty!(g_md2, :column_spacing, 15)

  #Settings for Constraint Consensus
  s_alpha_name = Label("Alpha")
  s_alpha_input = Entry()
  setproperty!(s_alpha_input, :text, s_alpha)

  s_beta_name = Label("Beta")
  s_beta_input = Entry()
  setproperty!(s_beta_input, :text, s_beta)

  s_ccpoints_name = Label("Points to Generate")
  s_ccpoints_input = Entry()
  setproperty!(s_ccpoints_input, :text, s_ccpoints)

  s_ccmaxit_name = Label("Max Iterations")
  s_ccmaxit_input = Entry()
  setproperty!(s_ccmaxit_input, :text, s_ccmaxit)

  g_md2[1, 1] = s_alpha_name
  g_md2[2, 1] = s_alpha_input
  g_md2[1, 2] = s_beta_name
  g_md2[2, 2] = s_beta_input
  g_md2[1, 3] = s_ccpoints_name
  g_md2[2, 3] = s_ccpoints_input
  g_md2[1, 4] = s_ccmaxit_name
  g_md2[2, 4] = s_ccmaxit_input

  push!(f2, g_md2)

  #Our frame for model information
  f3 = Frame("Range Cutting")
  setproperty!(f3, :margin, 15)

  #Grid for general settings
  g_md3 = Grid()
  setproperty!(g_md3, :margin, 10)
  setproperty!(g_md3, :column_spacing, 15)

  #Settings for Constraint Consensus
  s_max_points_name = Label("Maximum Points")
  s_max_points_input = Entry()
  setproperty!(s_max_points_input, :text, s_max_points)

  s_min_points_name = Label("Minimum Points")
  s_min_points_input = Entry()
  setproperty!(s_min_points_input, :text, s_min_points)

  s_point_every_x_name = Label("Point Every X")
  s_point_every_x_input = Entry()
  setproperty!(s_point_every_x_input, :text, s_point_every_x)

  g_md3[1, 1] = s_max_points_name
  g_md3[2, 1] = s_max_points_input
  g_md3[1, 2] = s_min_points_name
  g_md3[2, 2] = s_min_points_input
  g_md3[1, 3] = s_point_every_x_name
  g_md3[2, 3] = s_point_every_x_input

  push!(f3, g_md3)

  #Our frame for save or cancel buttons
  f4 = Frame("Actions")
  setproperty!(f4, :margin, 15)

  #Grid for general settings
  g_md4 = Grid()
  setproperty!(g_md4, :margin, 10)
  setproperty!(g_md4, :column_spacing, 15)

  #Buttons
  save_settings_btn = Button("Save")
  id_save_settings= signal_connect(settings_btn_callback, save_settings_btn, "button-press-event")

  cancel_settings_btn = Button("Cancel")
  id_cancel_settings= signal_connect(settings_btn_callback, cancel_settings_btn, "button-press-event")

  g_md4[1, 1] = save_settings_btn
  g_md4[2, 1] = cancel_settings_btn

  push!(f4, g_md4)

  settings_grid[1, 1] = f1
  settings_grid[1, 2] = f2
  settings_grid[1, 3] = f3
  settings_grid[1, 4] = f4

  #Push our grid items to main window
  push!(settings_window, settings_grid)
  showall(settings_window)

end

#Callback for when a button on the settings page is clicked
function settings_btn_callback(leaf, button)
  global unbounded_lower_value, unbounded_upper_value, s_alpha, s_beta, s_ccpoints, s_ccmaxit
  global s_ulv_input, s_uuv_input, s_alpha_input, s_beta_input, s_ccpoints_input, s_ccmaxit_input, settings_window
  global s_max_points_input, s_min_points_input, s_point_every_x_input
  global s_max_points, s_min_points, s_point_every_x

  #Get which button was clicked
  button_clicked = getproperty(leaf, :label, String)

  #If Save button clicked
  if button_clicked == "Save"

    unbounded_lower_value = parse(Int64, getproperty(s_ulv_input, :text, String))
    unbounded_upper_value = parse(Int64, getproperty(s_uuv_input, :text, String))

    s_alpha = parse(Float64, getproperty(s_alpha_input, :text, String))
    s_beta = parse(Float64, getproperty(s_beta_input, :text, String))
    s_ccmaxit = parse(Int64, getproperty(s_ccmaxit_input, :text, String))
    s_ccpoints = parse(Int64, getproperty(s_ccpoints_input, :text, String))
    s_max_points = parse(Int64, getproperty(s_max_points_input, :text, String))
    s_min_points = parse(Int64, getproperty(s_min_points_input, :text, String))
    s_point_every_x = parse(Int64, getproperty(s_min_points_input, :text, String))

  end

  #Close the window
  destroy(settings_window)

end
