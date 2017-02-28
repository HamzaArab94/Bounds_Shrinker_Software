using Ipopt
using AmplNLReader
using NLPModels
using ForwardDiff

#=
Attempts to shrink the bounds on the given NLP by using IPOPT
external solver
=#
function run2(filename)
  global m, current_var_index

  #Load AMPL model based on filename
  m = AmplModel(filename)


  #Create Ipopt problem from model
  prob = createProblem(m.meta.nvar, m.meta.lvar, m.meta.uvar, m.meta.ncon,
                       m.meta.lcon, m.meta.ucon, m.meta.nnzj, m.meta.nnzh,
                       eval_f, eval_g, eval_grad_f, eval_jac_g, eval_h)

  #Specify starting point
  prob.x = [0.0, 0.0]

  #Set index of current variable we are min/max'ignoring
  current_var_index = 1

  #Solve the problem
  status = solveProblem(prob)

  #Print out result
  #println(Ipopt.ApplicationReturnStatus[status])
  println(prob.x)
  println(prob.obj_val)

end

#=
Returns the value of the objective function at the current solution x
=#
function eval_f(x)
  global current_var_index

  #Return the variable we are maximizing or minimizing (right now this will just maximize)
  return x[current_var_index]
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
 
  #Evaluate the jacobian at x
  rows, cols, vals = jac_coord(m, x)
end

function eval_h(x, mode, rows, cols, obj_factor, lambda, vals)
  global m
  
  #Evaluate the product of the Lagrangian Hessian (not sure if function parameters are
  #correct, was focused on dealing with function not found issue
  rows, cols, vals = hprod(m, x, lamda, m.meta.y0, obj_factor)

end
