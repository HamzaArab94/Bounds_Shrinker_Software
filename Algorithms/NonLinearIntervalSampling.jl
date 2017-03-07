#http://www.sce.carleton.ca/faculty/chinneck/MProbe/MProbePaper2.pdf


using AmplNLReader,Gtk.ShortNames

#Print the Current Bounds of the Model
function PrintCurrentBounds(nvar::Int,lBOUND::Array,uBOUND::Array)
  for i = 1:nvar
    lbound = lBOUND[i]
    ubound = uBOUND[i]
    println("var" * string(i) * " -> [$lbound,$ubound]\n")
  end
end

#Determine if the point is feasible for the inequality constraint
function satisfiesInequalityConstraint(value::Array,z::Int,upper::Array,lower::Array)
  return (value[z] >= lower[z] && value[z] <= upper[z])
end

#Determine less than equality for a point
function satisfiesEqualityLTConstraint(value::Array,z::Int,upper::Array)
  return (value[z] <= upper[z])
end

#Determine greater than equality for a point
function satisfiesEqualityGTConstraint(value::Array,z::Int,lower::Array)
  return (value[z] >= lower[z])
end

#Genererate sample points within the given lvar->uvar range
function GenerateSamplingPoints(numOfPoints::Int,nvar::Int,lvar::Array,uvar::Array,numUnboundedL,numUnboundedU)
  SamplingPoints = Any[]
  for i = 1: numOfPoints
    arr_Point = Float64[]
    for j = 1: nvar
      lower = lvar[j]
      upper = uvar[j]
      if(lower <= numUnboundedL)
        lower = numUnboundedL
      end
      if(upper >= numUnboundedU)
        upper = numUnboundedU
      end
      point = rand(lower:upper)
      push!(arr_Point,point)
    end
    push!(SamplingPoints,arr_Point)
  end
  return SamplingPoints
end

#Find the (min,max) pairs for the inequality constraints
function findMaxMinPairInequality(nvar::Int,INEQ_feasiblePoints::Array)
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

#Find the (min,max) pairs for equality constraints
function findMaxMinPairEquality(nvar::Int,LTEQ_feasiblePoints::Array,GTEQ_feasiblePoints::Array)
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

#Tighten the bounds based on the (min,max) pairs.
#Makes sure that gaps between the min max are filled
function tightenBounds(INEQ_minmax::Array,EQ_minmax::Array,lvar::Array,uvar::Array,nvar::Int)
  for i = 1 : nvar
    temp = Any[]
    for j = 1 : 2
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

#Perform the Non Linear Interval Sampling Algorithm
function NonLinearIntervalSampling(model::AmplModel,numUnboundedU,numUnboundedL)

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
    SamplingPoints = GenerateSamplingPoints(5,nvar,lvar,uvar,numUnboundedL,numUnboundedU)
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
   if((length(INEQ_feasiblePoints) == 0) && (length(LTEQ_feasiblePoints) == 0 || length(GTEQ_feasiblePoints) == 0))
      println("No feasible points found during sampling.")
      return
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

