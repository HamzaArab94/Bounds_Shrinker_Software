using NLPModels
using AmplNLReader

#Load AMPL Model based on filename
model = AmplModel("basic_model.nl")

#Numerical Unbounded Constant
numUnboundedU = (1*10)^3
numUnboundedL = -(1*10)^3

#Prints the bounds at the beginning
function PrintBounds(nvar,lBOUND,uBOUND)

  println("Welcome to Non Linear Range Cutting Algorithm!\n")
  println("Beginning variable bounds\n")
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
function Cut(number,lower,upper)
  lex = [];
  for i = 1:number
    lex =  lower[i] + 100
    convert(Int64, lex)
    u = upper[i]
    println("var" * string(i) * " -> [$lex,$u]\n")
  end
  return lex
end

#Method that samples points
function GenerateSamplingPoints(numOfPoints,nvar,lvar,uvar,cut)
  SamplingPoints = Any[]
  for i = 1: numOfPoints
    arr_Point = Float64[]
    for j = 1: nvar
      point = rand(lvar[cut]:uvar[j])
      push!(arr_Point,point)
    end
    push!(SamplingPoints,arr_Point)
  end
  # for k = 1: numOfPoints
  #   p = SamplingPoints[k]
  #   println("point" * string(k) * " -> $p\n")
  # end
  return SamplingPoints
end


#function NonLinearRangeCutting(model)
   #Model info

# x1 = 100.0

# x2 = 100.0

  #Starting point
# x = [x1, x2]

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

PrintBounds(nvar, lvar, uvar)
# cut =
cut = Cut(nvar, lvar, uvar)
# println("The value of the cut is now " * string(cut) * "\n");
GenerateSamplingPoints(10, nvar, lvar, uvar, cut)
