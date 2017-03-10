#http://www.sce.carleton.ca/faculty/chinneck/MProbe/MProbePaper2.pdf
using AmplNLReader,Gtk.ShortNames

#Prints the current bounds of all variables
function PrintCurrentBounds(nvar,lBOUND,uBOUND)
  for i = 1:nvar
    lbound = lBOUND[i]
    ubound = uBOUND[i]
    println("var" * string(i) * " -> [$lbound,$ubound]\n")
  end
end

#Check if the inequality is satisfied
function satisfiesInequalityConstraint(value,z,upper,lower)
  return (value[z] >= lower[z] && value[z] <= upper[z])
end

#Check for greater than less than or equal to of equality constraint
function checkEqualityConstraint(econ,equalityConstraint)
  if(length(econ) > 0)
    for i in econ
      if((equalityConstraint[i][1] && equalityConstraint[i][2]) || equalityConstraint[i][3])
        return true
      end
    end
  end
  return false
end

#Generate Sampling Points
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

#Scale the Box in powers of 10
function ScaleBox(lowerBound,upperBound,both,lvar,uvar,scaleFactor)
  for k in lowerBound
    lvar[k] = lvar[k] * scaleFactor
  end
  for l in upperBound
    uvar[l] = uvar[l] * scaleFactor
  end
  for m in both
    lvar[m] = lvar[m] * scaleFactor
    uvar[m] = uvar[m] * scaleFactor
  end
end

#Used to go to the last accepted nucleus box
function reduceScale(lowerBound,upperBound,both,lvar,uvar,scaleFactor)
  for k in lowerBound
    lvar[k] = lvar[k] / scaleFactor
  end
  for l in upperBound
    uvar[l] = uvar[l] /  scaleFactor
  end
  for m in both
    lvar[m] = lvar[m] / scaleFactor
    uvar[m] = uvar[m] / scaleFactor
  end
end

#Create a bit array for equality constraints
function cBitArray(numOfConst)
  econstraints = Any[]
  for i = 1 : numOfConst
    push!(econstraints,[false,false,false])
  end
  return econstraints
end

function printArray(Array)
  for item in Array
    println(item)
  end
end

function GetANucleus(model,numUnboundedL,numUnboundedU)

  # Collect Model Information
  nvar = model.meta.nvar
  lvar = model.meta.lvar
  uvar = model.meta.uvar
  lower = model.meta.lcon
  upper = model.meta.ucon
  econ = model.meta.jfix
  icon = model.meta.ncon

  #Check if the model is unconstrained
  if(length(lower) == 0 && length(upper) == 0)
    println("No Constraints, Infinite FR ")
    return
  end
  #Check if the model has equality constraints
  if(length(econ) > 0)
    println("This model has equality constraints\n")
  end

  #Show original bounds
  println("Original Bounds Are:")
  PrintCurrentBounds(nvar,lvar,uvar)

  #Initialize Nucleus
  scaleLower = Any[]
  scaleUpper = Any[]
  scaleBoth = Any[]
  for i = 1:nvar
      if(lvar[i] <= numUnboundedL && uvar[i] >= numUnboundedU)
        lvar[i] = -1.0
        uvar[i] = 1.0
        push!(scaleBoth,i)
      elseif(lvar[i]>= numUnboundedL && uvar[i] >= numUnboundedU)
        if(lvar[i] > 1.0)
          uvar[i] = lvar[i] + 1
        else
          uvar[i] = 1.0
        end
        push!(scaleUpper,i)
      elseif(lvar[i] <= numUnboundedL && uvar[i] <= numUnboundedU)
        lvar[i] = -1.0
        push!(scaleLower,i)
      end
  end

  #Check if there are no unbounded variables in the model
  if(length(scaleLower) == 0 && length(scaleUpper) == 0 && length(scaleBoth) == 0)
    print("No unbounded variables in model\n")
    return
  end

  scaleFactor = 1
  complete = false
  while(!complete)
    #Sample the Nucleus Box
    println("Sampling Box is now:")
    PrintCurrentBounds(nvar,lvar,uvar)
    samplingPoints = GenerateSamplingPoints(nvar,nvar,lvar,uvar)
    println("Sampling....")
    feasiblePoints = Any[]
    equalityConstraint = cBitArray(icon)
    for point in samplingPoints
      value= try
        NLPModels.cons(model,point)
      catch AmplException
        continue
      end
      for z = 1 : length(value)
        if findfirst(econ,z) <= 0
          if (satisfiesInequalityConstraint(value,z,upper,lower))
            push!(feasiblePoints,point)
          end
        else
          if(value[z] > lower[z])
            equalityConstraint[z][1] = true
          elseif(value[z] < upper[z])
            equalityConstraint[z][2] = true
          else
            equalityConstraint[z][3] = true
          end
        end
      end
    end
    if(checkEqualityConstraint(econ,equalityConstraint) || (length(feasiblePoints) > 0))
      scaleFactor = scaleFactor * 10
      if(scaleFactor == 1000000)
        println("\nCan be further scaled\nScaling Box...")
        ScaleBox(scaleLower,scaleUpper,scaleBoth,lvar,uvar,scaleFactor)
        println("@Infinity, cannot scale further")
        PrintCurrentBounds(nvar,lvar,uvar)
        return [lvar,uvar]
      end
      println("\nCan be further scaled\nScaling Box...")
      ScaleBox(scaleLower,scaleUpper,scaleBoth,lvar,uvar,scaleFactor)
    else
      complete  = true
      println("no feasible points found going back to last box")
      reduceScale(scaleLower,scaleUpper,scaleBoth,lvar,uvar,scaleFactor)
      PrintCurrentBounds(nvar,lvar,uvar)
      return [lvar,uvar]
    end
  end
end
