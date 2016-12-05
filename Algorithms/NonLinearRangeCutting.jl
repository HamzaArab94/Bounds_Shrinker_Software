using NLPModels
using AmplNLReader

#Load AMPL Model based on filename
model = AmplModel("basic_model.nl")

#Collecl Model Information

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

x1 = 100.0

x2 = 100.0

#Starting point
x = [x1, x2]

function p(model)

  NLPModel.cons(model, [x1, x2]) 
  a = 0
  while a < 10
    a = a + 1
    for (i in lower)
      if(i > 0)
        print("This lower constraint is violated.")
        x3 = x1 / 5
        x1 = x1 - x3
        x = [x1, x2]
      end

      for (j in upper)
        if(i < 0)
          print("This upper constraint is violated.")
          x3 = x1 / 5
          x2 = x2 - x3
          x = [x1, x2]
        end
  end

      

    
