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
function Cut(number,lower, upper, bound, index)
  if(index == 1)
    lex = [];
    result = [];
    lex =  lower[bound] + 90
    lower[bound] = lower[bound] + 90
    lex = round(Int, lex)
    lex = lex - 90
    push!(result, lower[bound])
    push!(result, lower[bound] - 90)
  # push!(result, lex - 100)
  # println(result)
    return result
  elseif(index == 2)
    # println("I am here")
    lex = [];
    result = [];
    lex =  upper[bound] - 90
    upper[bound] = upper[bound] - 90
    lex = round(Int, lex)
    lex = lex + 90
    push!(result, upper[bound])
    push!(result, upper[bound] + 90)
  # push!(result, lex - 100)
  # println(result)
    return result
  elseif(index == 3)
    lex = [];
    result = [];
    lex =  lower[2] + 90
    lower[2] = lower[2] + 90
    lex = round(Int, lex)
    lex = lex - 90
    push!(result, lower[2])
    push!(result, lower[2] - 90)
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
      values = try
        NLPModels.cons(model,p)
      catch AmplException
        continue
      end
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

  Rounds = 40
  b = 1
  count = 0
# How to convert from Float to Int
# x = convert(Int64, 1.0)

  println("Welcome to Non Linear Range Cutting Algorithm!\n")
  println("Beginning variable bounds\n")
  PrintBounds(nvar, lvar, uvar)

  for i = 1:Rounds
    println(lvar[1])
    println(lvar[2])
    println(uvar[1])
    println(uvar[2])
    println("Round" * string(i) * "\n")
    println(b)
    cut = Cut(nvar, lvar, uvar, 1, b)
  # println("Do I get here?")
  # println(cut)
    PrintBounds(nvar, lvar, uvar)
    if(b == 2)
      Points = GenerateSamplingPoints(10, nvar, uvar, cut)
    else
      Points = GenerateSamplingPoints(10, nvar, lvar, cut)
    end
    CheckConstraints(ncon, Points)
    println(LTEQ_feasiblePoints)
    println(GTEQ_feasiblePoints)
    # if(empty!(INEQ_feasiblePoints))
    println(INEQ_feasiblePoints)
    if (count == 10)
      b = b + 1
      count = 0
    end
    count = count + 1
  # end
end
# empty!(a)
# rand(lower_bound_int:upper_bound_int)
