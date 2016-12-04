#http://www.sce.carleton.ca/faculty/chinneck/MProbe/MProbePaper2.pdf
using AmplNLReader

model = AmplModel("basic_model.nl")
#Numerical Unbounded Constant
numUnboundedU = (1*10)^20
numUnboundedL = -(1*10)^20

# Collect Model Information
nvar = model.meta.nvar
lvar = model.meta.lvar
uvar = model.meta.uvar
lower = model.meta.lcon
upper = model.meta.ucon

#Create a range of evenly spaced points
function createPoints(low,up,space)
  points = Any[]
  step = (up - low)/space
  for i = 1:space
    push!(points,low)
    low = low + step
  end
  push!(points,up)
  return points
end

#Generate all Sampling points given range for each variable
function createSamplingPoints(var1,var2)
  points = Any[]
  for i = 1: length(var1)
    for j = 1: length(var1)
      push!(points,[var1[i],var2[j]])
    end
  end
  return points
end

#Scale the bounds of the nucleus box
function scaleBox(lowerBound,upperBound,both,scaleFactor)
  for k in lowerBound
    lvar[k] = lvar[k] - scaleFactor
  end
  for l in upperBound
    uvar[l] = uvar[l] + scaleFactor
  end
  for m in both
    lvar[m] = lvar[m] - scaleFactor
    uvar[m] = uvar[m] + scaleFactor
  end
end

#Initialize the Nucleus
#Record which are scalable
scaleLower = Any[]
scaleUpper = Any[]
scaleBoth = Any[]
for i = 1:nvar
    if(lvar[i] <= numUnboundedL && uvar[i] >= numUnboundedU)
      lvar[i] = -1.0
      uvar[i] = 1.0
      push!(scaleBoth,i)
    elseif(lvar[i]>=0 && uvar[i] >= numUnboundedU)
      uvar[i] = 1.0
      push!(scaleUpper,i)
    elseif(lvar[i] <= numUnboundedL && uvar[i] < numUnboundedU)
      lvar[i] = -1.0
      push!(scaleLower,i)
    elseif(lvar[i] >= numUnboundedL && uvar[i] >= numUnboundedU)
      uvar[i] = 1
      push!(scaleUpper,i)
    end
end


#Sample the Box
scaleFactor = 0.005
complete = false
while(!complete)
  println("Sampling Box is now:")
  println("Lower bounds [x1,x2] -> $lvar")
  println("Upper bounds [x1,x2] -> $uvar")

  #Generate Sampling Points
  Ranges = []
  for i = 1: nvar
    push!(Ranges,createPoints(lvar[i],uvar[i],10))
  end
  samplingPoints = createSamplingPoints(Ranges[1],Ranges[2])

  println("Sampling....")
  feasiblePoints = Any[]
  infeasiblePoints = Any[]
  for j = 1 : length(samplingPoints)
    value = NLPModels.cons(model,samplingPoints[j])
    for z = 1 : length(value)
      if(value[z] >= lower[z] && value[z] <= upper[z])
        push!(feasiblePoints,samplingPoints[j])
      else
        push!(infeasiblePoints,samplingPoints[j])
      end
    end
  end

  if(length(infeasiblePoints) != 0)
    complete  = true
    println("Constraint Violated")
    println("Bounds Tightened to")
    println("[lx1,lx2] -> $lBOUND")
    println("[ux1,ux2] -> $uBOUND")
    println("Exiting")
  else
    println("No constraints Violated")
    lBOUND = lvar
    uBOUND = uvar
    println("Scaling Box...")
    scaleBox(scaleLower,scaleUpper,scaleBoth,scaleFactor)
  end
end
