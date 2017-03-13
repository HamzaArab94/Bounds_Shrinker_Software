
#Callback for load model menu item
function load_model_clicked_callback(leaf, button)
  global selected_model, selected_model_name, selected_algorithm

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
      setproperty!(shrink_bounds_btn, :sensitive, true)
    end

  else

    println("No file chosen")

  end

end

#Callback for when exit is clicked
function exit_clicked_callback(leaf, button)
  println("exit")
  quit()
end

#Callback for when shrink bounds is clicked
function shrink_bounds_clicked_callback(leaf, button)
  global selected_model, selected_algorithm, new_bounds


  #if the model has been specified
  if selected_model != "" && selected_algorithm != ""

    #Initialize new bounds array
    new_bounds = Array{Float64}(selected_model.meta.nvar, 2)

    if selected_algorithm == "Manual Range Cutting"
        return
    elseif selected_algorithm == "Get a Nucleus"

      GetANucleus.set_unbounded_lower_value(unbounded_lower_value)
      GetANucleus.set_unbounded_upper_value(unbounded_upper_value)
      GetANucleus.run(selected_model, new_bounds)

    elseif selected_algorithm == "Nonlinear Range Cutting"
      return
    elseif selected_algorithm == "Nonlinear Interval Sampling"

      NonLinearIntervalSampling.set_unbounded_lower_value(unbounded_lower_value)
      NonLinearIntervalSampling.set_unbounded_upper_value(unbounded_upper_value)
      NonLinearIntervalSampling.run(selected_model, new_bounds)

    elseif selected_algorithm == "Constraint Consensus"

      ConstraintConsensus.set_unbounded_lower_value(unbounded_lower_value)
      ConstraintConsensus.set_unbounded_upper_value(unbounded_upper_value)
      ConstraintConsensus.run(selected_model, new_bounds)

    elseif selected_algorithm == "Exact Solution"
      return
    end

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

#Callback for when alorithm selected
function select_algorithm_clicked_callback(leaf, button)
  global selected_algorithm, shrink_bounds_btn, selected_model, saf_name

  selected_algorithm = getproperty(leaf, :label, String)
  setproperty!(saf_name, :label, selected_algorithm)

  #Hide all algorithm options
  hide_all_algorithm_options()

  #Show algorithm options for the selected algorithm
  #show_selected_algorithm_options()

  #if the model is not empty, we are ready to shrink
  if selected_model != ""
    setproperty!(shrink_bounds_btn, :sensitive, true)
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

      new_lower = new_bounds[counter, 1]
      new_upper = new_bounds[counter, 2]

      percent_change_lower_val = ((current_lower - new_lower) / current_lower) * 100
      percent_change_upper_val = ((current_upper - new_upper) / current_upper) * 100

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

# Hides all algorithm specific options
function hide_all_algorithm_options()
  global s_alpha_name, s_alpha_input, s_beta_name, s_beta_input, s_points_name, s_points_input, s_maxit_name, s_maxit_input

  println("hiding")
  setproperty!(s_alpha_name, :visible, false)
  setproperty!(s_alpha_input, :visible, false)
  setproperty!(s_beta_name, :visible, false)
  setproperty!(s_beta_input, :visible, false)
  setproperty!(s_points_name, :visible, false)
  setproperty!(s_points_input, :visible, false)
  setproperty!(s_maxit_name, :visible, false)
  setproperty!(s_maxit_input, :visible, false)

end

function show_selected_algorithm_options()
  global g_sa, f3, selected_algorithm, s_alpha_name, s_alpha_input, s_beta_name, s_beta_input, s_points_name, s_points_input, s_maxit_name, s_maxit_input

  if selected_algorithm == "Constraint Consensus"

    #Constraint consensus option locations
    g_sa[1, 2] = s_points_name
    g_sa[2, 2] = s_points_input

    g_sa[1, 3] = s_maxit_name
    g_sa[2, 3] = s_maxit_input

    g_sa[1, 4] = s_alpha_name
    g_sa[2, 4] = s_alpha_input

    g_sa[1, 5] = s_beta_name
    g_sa[2, 5] = s_beta_input

    g_sa[1, 6] = shrink_bounds_btn
    g_sa[2, 6] = accept_bounds_btn

  end

end
