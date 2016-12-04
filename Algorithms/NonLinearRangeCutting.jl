using NLPModels
using AmplNLReader
using ForwardDiff

c = 0                  #Number of constraints
alpha = 0.5            #Feasibility distance tolerance
beta = 0.1             #Vector length tolerance

function program(filename)
  global c, alpha, beta
  
  #Load AMPL Model based on filename
  m = AmplModel(filename)

  #Get number of constraints from Model
  c = m.meta.ncon

  #Starting point
  x = [100.0, 100.0]

  y = 100.0

  #Set Counter to 0
  i = 0

  #Iterating through 10 times for development
  while i < 10
    i = i + 1

    #Number of violated constraints for a given variable
    n = Int64[m.meta.nvar]
    
    #Number of constraints violated
    ninf = 0

    #Constraint counter for looping all constraints
    constraint_counter = 1
    
    #Loop each constraints
    for c in cons(m, x)

      constraint_violated = false
      d = 1
      violation = 0

      #If upper bound constraint is violated
      if c > m.meta.ucon[constraint_counter]

        constraint_violated = true
        d = -1
        violation = c - m.meta.ucon[constraint_counter]
        println("Constraint $constraint_counter upper bound was violated ($c)")
        z = y
        y = y / 5
        x = [z,y]
      else
        println("Constraint $constraint_counter upper bound was not violated ($c)")

      end

      if c < m.meta.lcon[constraint_counter]

        violation = m.mSharedVectoreta.lcon[constraint_counter] - c
        constraint_violated = true
        println("Constraint $constraint_counter lower bound was violated ($c)")
        z = y
        y = (y/5)
        x = [y,z]

      else

        println("Constraint $constraint_counter lower bound was not violated ($c)")

      end
    end
  end
      


      

    
