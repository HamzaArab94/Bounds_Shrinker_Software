using Ipopt
using AmplNLReader
using NLPModels
using ForwardDiff

new_bounds = Array{Float64}

#=
Attempts to shrink the bounds on the given NLP by using IPOPT
external solver
=#
function run2(filename)
  global m, current_var_index

  #Load AMPL model based on filename
  m = AmplModel(filename)


  #Create Ipopt problem from model to maximize
  prob_max = createProblem(m.meta.nvar, m.meta.lvar, m.meta.uvar, m.meta.ncon,
                       m.meta.lcon, m.meta.ucon, m.meta.nnzj, m.meta.nnzh,
                       eval_f_max, eval_g, eval_grad_f, eval_jac_g, eval_h)

  #Create Ipopt problem from model to minimize
  prob_max = createProblem(m.meta.nvar, m.meta.lvar, m.meta.uvar, m.meta.ncon,
                       m.meta.lcon, m.meta.ucon, m.meta.nnzj, m.meta.nnzh,
                       eval_f_min, eval_g, eval_grad_f, eval_jac_g, eval_h)

  #Set index of current variable we are min/max'ignoring
  current_var_index = 1

  #For each variable in the NLP
  while current_var_index <= m.meta.nvar

    #Solve the max and min prob;em
    status_max = solveProblem(prob_max)
    status_min = solveProblem(prob_min)

    #Assign minimum variable value to variable bounds
    new_bounds[current_var_index, 1] = prob_min.obj_val

    #Assign maximum variable value to variable bounds
    new_bounds[current_var_index, 2] = prob_max.obj_val

    #Move to next variable
    current_var_index = current_var_index + 1

  end

  #Return the shrunken bounds
  return new_bounds

end

#=
Returns the value of the objective function at the current solution x
Maximize x
=#
function eval_f_max(x)
  global current_var_index

  #Return the current variable to maximize
  return x[current_var_index]
end

#=
Returns the value of the objective function at the current solution x
Minimize x
=#
function eval_f_min(x)
  global current_var_index

  #Return the current variable to minimize
  return -x[current_var_index]
end

#=
Sets the value of the constraint functions g at the current solution x:
=#
function eval_g(x, g)
  global m

  #Constraint counter for looping all constraints
  constraint_counter = 1

  #Loop each constraint
  for c in cons(m, x)

    #Assign value of constraint function
    g[constraint_counter] = jth_congrad(m, x, constraint_counter)

    #Increment constraint counter
    constraint_counter = constraint_counter + 1

  end

end

#=
Sets the value of the gradient of the objective function at the current solution x:
=#
function eval_grad_f(x, grad_f)
  global m

  #Evaluate gradient of objective function at x
  grad_f = grad(m, x)

end

#=
Returns the Jacobian at x
=#
function eval_jac_g(x, mode, rows, cols, vals)
  global m
  return
  rows, cols, vals = jac_coord(m, x)
end

function eval_h(x, mode, rows, cols, obj_factor, lambda, vals)
  global m
  rows, cols, vals = hprod(m, x, lamda, m.meta.y0, obj_factor)

end

function eval_g(x, g)
  global m

  #Constraint counter for looping all constraints
  constraint_counter = 1

  #Loop each constraint
  for c in cons(m, x)

    #Assign value of constraint function
    g[constraint_counter] = jth_congrad(m, x, constraint_counter)

    #Increment constraint counter
    constraint_counter = constraint_counter + 1

  end

end

#=
Sets the value of the gradient of the objective function at the current solution x:
=#
function eval_grad_f(x, grad_f)
  global m

  #Evaluate gradient of objective function at x
  grad_f = grad(m, x)

end

#=
Returns the Jacobian at x
=#
function eval_jac_g(x, mode, rows, cols, vals)
  global m
 
  #Evaluate the jacobian at x
  rows, cols, vals = jac_coord(m, x)
end

function eval_h(x, mode, rows, cols, obj_factor, lambda, vals)
  global m
  
  #Evaluate the product of the Lagrangian Hessian (not sure if function parameters are
  #correct, was focused on dealing with function not found issue
  rows, cols, vals = hprod(m, x, lamda, m.meta.y0, obj_factor)

end
