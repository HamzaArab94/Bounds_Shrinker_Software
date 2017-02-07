using NLPModels
using AmplNLReader
using ForwardDiff

c = 0           #Number of constraints
alpha = 0.5     #Feasibility distance tolerance
beta = 0.1      #Vector length tolerance

function run(filename)
  global c, alpha, beta

  #Load AMPL model based on filename
  m = AmplModel(filename)

  #Get number of constraints from model
  c = m.meta.ncon

  #Starting point
  x = [10.0, 10.0]

  #Set counter to 0
  i = 0

  #Maximum number of iterations is 10 for development
  while i < 10
    i = i + 1

    #Number of violated constraints for a given variable
    n = Array{Int64}(m.meta.nvar)

    #Our component vector for single constraint
    f_vector = Array{Float64}(m.meta.nvar)

    #Sum of component vectors for the variable over the feasibility vectors for all violated constraints
    s_vector = Array{Float64}(m.meta.nvar)

    #Number of constraints violated
    ninf = 0

    #Consensus vectors
    t_vector = Array{Float64}(m.meta.nvar)

    #Constraint counter for looping all constraints
    constraint_counter = 1

    #Loop each constraint
    for c in cons(m, x)

      constraint_violated = false #Upper or lower bound violated?
      d = 1; #Used for direction of feasibility vector
      violation = 0; #Amount the constraint was violated by

      #If the constraint upper bound is violated
      if c > m.meta.ucon[constraint_counter]

        constraint_violated = true
        d = -1
        violation = c - m.meta.ucon[constraint_counter]
        println("Constraint $constraint_counter upper bound was violated ($c)")

      else

        println("Constraint $constraint_counter uper bound  not violated ($c)")

      end

      #If the constraint lower bound is violated
      if c < m.meta.lcon[constraint_counter]

        violation = m.mSharedVectoreta.lcon[constraint_counter] - c
        constraint_violated = true
        println("Constraint $constraint_counter lower bound was violated ($c)")

      else

        println("Constraint $constraint_counter lower bound not violated ($c)")

      end

      #If upper or lower bound was violated
      if constraint_violated

          println("Constraint violation is $violation")

          #Calculate gradient
          c_grad = jth_congrad(m, x, constraint_counter)

          println("Gradient is $c_grad")

          #Feasibility vector calculation bottom value
          gradient_vector_squared_sum = 0

          #Get sum of each variables gradient vector squared
          for a in c_grad
            gradient_vector_squared_sum = gradient_vector_squared_sum + a ^ 2
          end

          #Counter for looping variables
          x_counter = 1

          #Set each component of feasibility vector
          for x_value in x

            if c_grad[x_counter] != 0

              #Feasibility vector calculation based on gradient, violation and direction
              f_vector[x_counter] = (violation * d * c_grad[x_counter]) / gradient_vector_squared_sum

              #Increment count for variable being present in constraint violation
              n[x_counter] = n[x_counter] + 1

            end

            #Continue to next variable
            x_counter = x_counter + 1

          end

          #Calculate distance of feasibility vector
          distance_sum = 0
          for f in f_vector
            distance_sum = distance_sum + f ^ 2
          end

          #Distance is root of sum of each length squared
          distance = sqrt(distance_sum)

          println("The distance of the component vector is $distance")

          #If feasibility distance greater than alpha
          if distance > alpha

            println("Feasibility distance is greater than alpha")

            #Increment the number of constraints violated
            ninf = ninf + 1

            println("Number of constraints violated is now $ninf")
            #==
            NEED TO FIGURE OUT HOW TO DETERMINE WHICH VARIABLES INVOLVED IN
            CONSTRAINT VIOLATION
            ==#

            #Add to sum of feasibility vectors from violated constraints
            f_counter = 1
            for f in f_vector
              s_vector[f_counter] = s_vector[f_counter] + f
              f_counter = f_counter + 1
            end

            println("Sum of feasibility vectors from violated constraints is:")
            println(s_vector)

          #Feasibility distance less than alpha
          else

            println("Feasibility distance is too small, ignoring this.")

          end

      #If constraint not violated
      else

        println("Constraint $constraint_counter was not violated")

      #End if constraint violated
      end

      #Increment constraint counter
      constraint_counter = constraint_counter + 1

    #End constraint loop
    end

    #If no constraints violated
    if ninf == 0

      println("No constraints violated! Exiting.")
      break;

    end

    #Calculate consensus vector
    s_counter = 1
    for s in s_vector
      t_vector[s_counter] = s / n[s_counter]
      s_counter = s_counter + 1
    end

    println("Consensus vector calculated as:")
    println(t_vector)

    #Calculate length of consensus vector
    t_vector_sum = 0
    for t in t_vector
      t_vector_sum = t_vector_sum + t^2
    end
    t_vector_length = sqrt(t_vector_sum)

    #If the length of the consensus vector is too short exit unsuccessfully
    if t_vector_length < beta
      println("Length of consensus vector is too short, exiting unsuccssfully")
    end

    #Move to new position and repeat
    t_counter = 1
    for t in t_vector
      x[t_counter] = x[t_counter] + t
      t_counter = t_counter + 1
    end

    println("New position:")
    println(x)

  #End while loop
  end

end
