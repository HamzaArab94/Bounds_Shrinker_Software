#http://www.sce.carleton.ca/faculty/chinneck/MProbe/MProbePaper2.pdf
using NLPModels
using AmplNLReader

# model = AmplModel("basic_model.nl")

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

function BoxLower(percent, lower, upper)
  r = length(collect(lower: upper))
  box = r * percent
  return [round(Int, lower), round(Int,lower + box)]
end

function BoxUpper(percent, lower, upper)
  r = length(collect(lower: upper))
  box = r * percent
  return [round(Int, upper), round(Int,upper - box)]
end

#Check Whether we can cut or not
function Cut(LTEQ_feasiblePoints, GTEQ_feasiblePoints, INEQ_feasiblePoints)
  if(isempty(LTEQ_feasiblePoints) && isempty(GTEQ_feasiblePoints) && isempty(INEQ_feasiblePoints))
    return true
  end
  return false
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
  return SamplingPoints
end


function NonLinearRangeCutting(model)
   #Model info

  #Number of variables
  nvar = model.meta.nvar

  #Copy of nvar
  nvar_replace = nvar

  #Lower Bound of all variables
  lvar = model.meta.lvar

  #Copy of lvar
  lvar_replace = lvar

  #Upper Bound of all variables
  uvar = model.meta.uvar

  #Copy of uvar
  uvar_replace = uvar

  #Lower Bound of all constraints
  lower = model.meta.lcon

  #Upper Bound of all constraints
  upper = model.meta.ucon

  #Equality Constraints
  econ = model.meta.jfix

  #Number of Constraints
  ncon = model.meta.ncon

  #30% of all cuts (Templated)
  p = 0.3

  #Lists to determine feasible points of expected region
  LTEQ_feasiblePoints = Any[]
  GTEQ_feasiblePoints = Any[]
  INEQ_feasiblePoints = Any[]

  #indexing elements in lvar,uvar
  b = 1

  #Represent # of Rounds for every cut
  i = 1

  println("Welcome to Non Linear Range Cutting Algorithm!\n")
  println("Beginning variable bounds\n")
  PrintBounds(nvar, lvar, uvar)

  while (i < 2)
      println("Round " * string(i) * "\n")
      box = BoxLower(p, lvar_replace[b], uvar_replace[b])
      lvar_replace[b] = box[b]
      uvar_replace[b] = box[b + 1]
      Points = GenerateSamplingPoints(10, nvar_replace, lvar_replace, uvar_replace)
      CheckConstraints(ncon, Points)
      if(Cut(LTEQ_feasiblePoints, GTEQ_feasiblePoints, INEQ_feasiblePoints))
        println("This cut is possible.")
        lvar[b] = box[2]
        PrintBounds(nvar, lvar, uvar)
        p = 0.3
        i = i + 1
      end
      p = p / 2
    end
end
