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
function Cut(number,lower, bound)
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
  for k = 1: numOfPoints
     p = SamplingPoints[k]
     println("point" * string(k) * " -> $p\n")
   end
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

Rounds = 10
# How to convert from Float to Int
# x = convert(Int64, 1.0)

println("Welcome to Non Linear Range Cutting Algorithm!\n")
println("Beginning variable bounds\n")
PrintBounds(nvar, lvar, uvar)

for i = 1:Rounds
  println("Round" * string(i) * "\n")
  a = lvar[1]
  b = lvar[2]
  c = uvar[1]
  d = uvar[2]
  println("Bounds: -> [$a,$b,$c,$d]\n")
  cut = Cut(nvar, lvar, 1)
  println(cut)
  # println(uvar)
  PrintBounds(nvar, lvar, uvar)
  # println(cut)
# println("The value of the cut is now " * string(cut) * "\n");
  GenerateSamplingPoints(10, nvar, lvar, uvar)
end

# rand(lower_bound_int:upper_bound_int)
