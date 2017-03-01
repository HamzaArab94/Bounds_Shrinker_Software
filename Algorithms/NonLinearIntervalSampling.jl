#http://www.sce.carleton.ca/faculty/chinneck/MProbe/MProbePaper2.pdf
using AmplNLReader,Gtk.ShortNames

#Numerical Unbounded Constant
numUnboundedU = (1*10)^20
numUnboundedL = -(1*10)^20

function PrintCurrentBounds(nvar,lBOUND,uBOUND)
  for i = 1:nvar
    lbound = lBOUND[i]
    ubound = uBOUND[i]
    println("var" * string(i) * " -> [$lbound,$ubound]\n")
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

function findMaxMinPairInequality(nvar,INEQ_feasiblePoints)
  minmax = Any[]
  for i = 1 : nvar
    temp = Any[]
    for j = 1 : length(INEQ_feasiblePoints)
      push!(temp,INEQ_feasiblePoints[j][i])
    end
    push!(minmax,extrema(temp))
  end
  return minmax
end

function findMaxMinPairEquality(nvar,LTEQ_feasiblePoints,GTEQ_feasiblePoints)
  minmax = Any[]
  for i = 1 : nvar
    temp = Any[]
    buffer = Any[]
    for j = 1 : length(GTEQ_feasiblePoints)
      push!(temp,GTEQ_feasiblePoints[j][i])
    end
    push!(buffer,minimum(temp))
    temp = Any[]
    for j = 1 : length(LTEQ_feasiblePoints)
      push!(temp,LTEQ_feasiblePoints[j][i])
    end
    push!(buffer,maximum(temp))
    push!(minmax,buffer)
  end
  return minmax
end

function printArray(array)
  for item in array
    println(array)
  end
end

function tightenBounds(INEQ_minmax,EQ_minmax,lvar,uvar,nvar)
  for i = 1 : nvar
    temp = Any[]
    for j = 1 : nvar
      if(length(INEQ_minmax) > 0)
        push!(temp,INEQ_minmax[i][j])
      end
      if(length(EQ_minmax) > 0)
        push!(temp,EQ_minmax[i][j])
      end
    end
    lvar[i] = minimum(temp)
    uvar[i] = maximum(temp)
  end
end

function NonLinearIntervalSampling(model)

  # Collect Model Information
  nvar = model.meta.nvar
  lvar = model.meta.lvar
  uvar = model.meta.uvar
  lower = model.meta.lcon
  upper = model.meta.ucon
  econ = model.meta.jfix
  ncon = model.meta.ncon

  println("Current Bounds Are:")
  PrintCurrentBounds(nvar,lvar,uvar)

  LTEQ_feasiblePoints = Any[]
  GTEQ_feasiblePoints = Any[]
  INEQ_feasiblePoints = Any[]
  INEQ_minmax = Any[]
  EQ_minmax = Any[]

  #For Each Constraint
  for i = 1 : ncon
    #Generate Sampling Points
    SamplingPoints = GenerateSamplingPoints(5,nvar,lvar,uvar)
    for point in SamplingPoints
      #Get the functional value
      values = NLPModels.cons(model,point)
      #Equality Constraint
      if findfirst(econ,i) > 0
        if (satisfiesEqualityLTConstraint(values,i,upper))
          push!(LTEQ_feasiblePoints,point)
        elseif (satisfiesEqualityGTConstraint(values,i,lower))
          push!(GTEQ_feasiblePoints,point)
        end
      #Inequality Constraint
      else
        if(satisfiesInequalityConstraint(values,i,upper,lower))
          push!(INEQ_feasiblePoints,point)
        end
      end
    end
   end
    #Find Minimum/Maximum Pair
    if(length(INEQ_feasiblePoints) > 0)
      INEQ_minmax = findMaxMinPairInequality(nvar,INEQ_feasiblePoints)
    end
    if (length(LTEQ_feasiblePoints) > 0  && length(GTEQ_feasiblePoints) > 0)
      EQ_minmax= findMaxMinPairEquality(nvar,LTEQ_feasiblePoints,GTEQ_feasiblePoints)
    end
    tightenBounds(INEQ_minmax,EQ_minmax,lvar,uvar,nvar)
    println("Tightened Bounds Are:")
    PrintCurrentBounds(nvar,lvar,uvar)
 end


Bounds = NonLinearIntervalSampling(AmplModel("TestModels/Bounded/TwoVariables/zecevic4.nl"))
