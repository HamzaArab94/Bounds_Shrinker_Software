#http://www.sce.carleton.ca/faculty/chinneck/MProbe/MProbePaper2.pdf
using NLPModels
using AmplNLReader

#Load AMPL Model based on filename
model = AmplModel("basic_model.nl")

#Numerical Unbounded Constant
numUnboundedU = (1*10)^3
numUnboundedL = -(1*10)^3

#Prints the bounds at the beginning
function PrintBounds(nvar,lBOUND,uBOUND)

  for i = 1:nvar
    lbound = lBOUND[i]
    if(lbound == -Inf)
      lbound = numUnboundedL
      lBOUND[i] = numUnboundedL
    end
    ubound = uBOUND[i]
    if(ubound == Inf)
      ubound = numUnboundedU
      uBOUND[i] = numUnboundedU
    end
    println("var" * string(i) * " -> [$lbound,$ubound]\n")
  end
end

#Perform cut
function Cut(number,lower, bound, index)
  if(index == 1)
    lex = [];
    result = [];
    lex =  lower[bound] + 100
    lower[bound] = lower[bound] + 100
    lex = round(Int, lex)
    lex = lex - 100
    push!(result, lower[bound])
    push!(result, lower[bound] - 100)
  # push!(result, lex - 100)
  # println(result)
    return result
  elseif(index == 2)
    lex = [];
    result = [];
    lex =  upper[bound] - 100
    upper[bound] = upper[bound] - 100
    lex = round(Int, lex)
    lex = lex + 100
    push!(result, upper[bound])
    push!(result, upper[bound] + 100)
  # push!(result, lex - 100)
  # println(result)
    return result
  elseif(index == 3)
    lex = [];
    result = [];
    lex =  lower[bound+1] + 100
    lower[bound+1] = lower[bound+1] + 100
    lex = round(Int, lex)
    lex = lex - 100
    push!(result, lower[bound+1])
    push!(result, lower[bound+1] - 100)
  # push!(result, lex - 100)
  # println(result)
    return result
  elseif(index == 4)
    lex = [];
    result = [];
    lex =  upper[bound+1] - 100
    lower[bound+1] = upper[bound+1] - 100
    lex = round(Int, lex)
    lex = lex + 100
    push!(result, upper[bound+1])
    push!(result, upper[bound+1] + 100)
  # push!(result, lex - 100)
  # println(result)
    return result
  end
end

function satisfiesInequalityConstraint(value,z,upper,lower)
  return (value[z] >= lower[z] && value[z] <= upper[z])
end

function satisfiesEqualityLTConstraint(value,z,upper)
  return (value[z] <= upper[z])
end

function satisfiesEqualityGTConstraint(value,z,lower)
  return (value[z] >= lower[z])
end

#Method to check each point and verify that it is not satisfied
function CheckConstraints(ncon, Points)

  #For Each Constraint
  for i = 1 : ncon
  #Generate Sampling Points
    # SamplingPoints = GenerateSamplingPoints(10,nvar,lvar,cut)
    for p in Points
    #Get the functional value
      values = NLPModels.cons(model,p)
    #Equality Constraint
      if findfirst(econ,i) > 0
        if (satisfiesEqualityLTConstraint(values,i,upper))
          push!(LTEQ_feasiblePoints,p)
        elseif (satisfiesEqualityGTConstraint(values,i,lower))
          push!(GTEQ_feasiblePoints,p)
        end
    #Inequality Constraint
      else
        if(satisfiesInequalityConstraint(values,i,upper,lower))
          push!(INEQ_feasiblePoints,p)
        end
      end
    end
  end
end

#Method that samples points
function GenerateSamplingPoints(numOfPoints,nvar,lvar,uvar)
  SamplingPoints = Any[]
  for i = 1: numOfPoints
    arr_Point = Float64[]
    for j = 1: nvar
      point = rand(lvar[j]:uvar[j])
      push!(arr_Point,point)
    end
    push!(SamplingPoints,arr_Point)
  end
  # for k = 1: numOfPoints
  #   p = SamplingPoints[k]
    #  println("point" * string(k) * " -> $p\n")
   # end
  return SamplingPoints
end

#function NonLinearRangeCutting(model)
   #Model info

  #Number of variables
  nvar = model.meta.nvar

  #Lower Bound of all variables
  lvar = model.meta.lvar

  #Upper Bound of all variables
  uvar = model.meta.uvar

  #Lower Bound of all constraints
  lower = model.meta.lcon

  #Upper Bound of all constraints
  upper = model.meta.ucon

  #Equality Constraints
  econ = model.meta.jfix

  #Number of Constraints
  ncon = model.meta.ncon

  LTEQ_feasiblePoints = Any[]
  GTEQ_feasiblePoints = Any[]
  INEQ_feasiblePoints = Any[]

  Rounds = 12
  b = 1
# How to convert from Float to Int
# x = convert(Int64, 1.0)

  println("Welcome to Non Linear Range Cutting Algorithm!\n")
  println("Beginning variable bounds\n")
  PrintBounds(nvar, lvar, uvar)

  for i = 1:Rounds
    println("Round" * string(i) * "\n")
    println(b)
    cut = Cut(nvar, lvar, 1, b)
    println("Do I get here?")
  # println(cut)
    PrintBounds(nvar, lvar, uvar)
    Points = GenerateSamplingPoints(1000, nvar, lvar, cut)
    CheckConstraints(ncon, Points)
    # println(LTEQ_feasiblePoints)
    # println(GTEQ_feasiblePoints)
    # if(empty!(INEQ_feasiblePoints))
    # println(INEQ_feasiblePoints)
    if (length(INEQ_feasiblePoints) != 0)
      b = b + 1
    end
  # end
end
# empty!(a)
# rand(lower_bound_int:upper_bound_int)

