module ConstraintConsensus

  using NLPModels
  using AmplNLReader
  using ForwardDiff

  alpha = 0.5                       #Feasibility distance tolerance
  beta = 0.1                        #Vector length tolerance
  max_iterations = 1000             #Maximum number of constraint consensus
  unbounded_lower_value = -(1*10)^3  #Value to replace infinity with on bounds
  unbounded_upper_value = (1*10)^3  #Value to replace infinity with on bounds
  points_to_generate = 10           #Number of random points to generate
  mutex = RemoteChannel()           #For mutex
  new_bounds = Array{Float64}


  #=
  Attempts to shrink the bounds on the given NLP by randomly generating
  points on the upper bound, lower bound, and randomly interim for each
  dimension and applying the constraint consensus method to each point.
  =#
  function run(m::AmplModel, new_bounds_ref)
    global c, points_to_generate, new_bounds

    println("Shrinking $points_to_generate points")
    #Generate random points
    random_points = generate(m, points_to_generate)

    #Array for shrunked bounds
    new_bounds = Array{Float64}(m.meta.nvar, 2)

    #For each random point generated
    #=
    @sync @parallel for x in random_points
    @syc and @parallel were causing a strange error related to
    mSharedVectoreta. Could not find anything on it, parallelism
    removed for now until I can find a solution.
    =#
    for x in random_points

      println("shrinking new point")

      #Move point x closer to the feasible region using constraint consensus
      move(m, x)

    end

    #Save current bounds in new bounds
    counter = 1
    while counter <= m.meta.nvar
      new_bounds_ref[counter, 1] = new_bounds[counter, 1]
      new_bounds_ref[counter, 2] = new_bounds[counter, 2]
      counter = counter + 1
    end

    return

  end

  #=
  Generates random points on the upper bound, lower bound, and
  randomly interim for each dimension
  =#
  function generate(m, to_generate)
    global unbounded_lower_value, unbounded_upper_value

    #Array of random points to return
    random_points = Array{Array{Float64}}(to_generate)

    #Counter for random points generated
    p_count = 1

    #For each random point to generate
    while p_count <= to_generate

      #Initialize random point
      p = Float64[]

      #Counter for dimension loop
      d_count = 1

      #For each dimension
      while d_count <= m.meta.nvar

        #Generate a random number
        random_num = rand(1:3)

        #Lower bound as integer
        lower_bound_int = floor(m.meta.lvar[d_count])

        #If negative infinity use infinity value
        if lower_bound_int == -Inf
          lower_bound_int = unbounded_lower_value
        end

        #Upper bound as integer
        upper_bound_int = ceil(m.meta.uvar[d_count])

        #If infinity use infinity value
        if upper_bound_int == Inf
          upper_bound_int = unbounded_upper_value
        end

        #If 1 then place on upper bound of dimension
        if random_num == 1

          #Assign value to point for dimension
          push!(p, upper_bound_int)

        #If 2 then place on lower bound of dimension
        elseif random_num == 2

            #Assign value to point for dimension
            push!(p, lower_bound_int)

        #If 3/otherwise we place randomly interim
        else

          #Generate randomly between upper and lower
          randomly_interim = rand(lower_bound_int:upper_bound_int)

          #Assign value to point for dimension
          push!(p, randomly_interim)

        end

        #Increment dimension counter
        d_count = d_count + 1

      end

      #Add point to array to return
      random_points[p_count] = p

      #Increment point counter
      p_count = p_count + 1

    end

    #Return our array of random points
    return random_points

  end

  #=
  Moves a given point x closer to the feasible region using the constraint
  consensus method.
  =#
  function move(m, x)
    global c, alpha, beta, max_iterations

    #Set counter to 0
    i = 0

    #Maximum number of iterations is 10 for development
    while i < max_iterations
      i = i + 1

      #Number of violated constraints for a given variable
      n = Array{Int64}(m.meta.nvar)
      counter = 1
      for x_value in x
        n[counter] = 0
        counter = counter + 1
      end

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
          println("($(myid())) Constraint $constraint_counter upper bound was violated ($c)")

        else

          println("($(myid())) Constraint $constraint_counter uper bound  not violated ($c)")

        end

        #If the constraint lower bound is violated
        if c < m.meta.lcon[constraint_counter]

          violation = m.mSharedVectoreta.lcon[constraint_counter] - c
          constraint_violated = true
          println("($(myid())) Constraint $constraint_counter lower bound was violated ($c)")

        else

          println("($(myid())) Constraint $constraint_counter lower bound not violated ($c)")

        end

        #If upper or lower bound was violated
        if constraint_violated

            println("($(myid())) Constraint violation is $violation")

            #Calculate gradient
            c_grad = jth_congrad(m, x, constraint_counter)

            println("($(myid())) Gradient is $c_grad")

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

              cgradprint = c_grad[x_counter]

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

            println("($(myid())) The distance of the component vector is $distance")

            #If feasibility distance greater than alpha
            if distance > alpha

              println("($(myid())) Feasibility distance is greater than alpha")

              #Increment the number of constraints violated
              ninf = ninf + 1

              println("($(myid())) Number of constraints violated is now $ninf")

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

              println("($(myid())) Sum of feasibility vectors from violated constraints is:")
              println(s_vector)

            #Feasibility distance less than alpha
            else

              println("($(myid())) Feasibility distance is too small, ignoring this.")

            end

        #If constraint not violated
        else

          println("($(myid())) Constraint $constraint_counter was not violated")

        #End if constraint violated
        end

        #Increment constraint counter
        constraint_counter = constraint_counter + 1

      #End constraint loop
      end

      #If no constraints violated
      if ninf == 0

        println("($(myid())) No constraints violated or feasibility distance too small, exiting.")
        break;

      end

      #Calculate consensus vector
      s_counter = 1
      for s in s_vector
        s2 = n[s_counter]
        println("$s / $s2")
        t_vector[s_counter] = s / n[s_counter]
        s_counter = s_counter + 1
      end

      println("($(myid())) Consensus vector calculated as:")
      println(t_vector)

      #Calculate length of consensus vector
      t_vector_sum = 0
      for t in t_vector
        t_vector_sum = t_vector_sum + t^2
      end
      t_vector_length = sqrt(t_vector_sum)

      #If the length of the consensus vector is too short exit unsuccessfully
      if t_vector_length < beta
        println("($(myid())) Length of consensus vector is too short, exiting unsuccssfully")
      end

      #Move to new position and repeat
      t_counter = 1
      for t in t_vector
        x[t_counter] = x[t_counter] + t
        t_counter = t_counter + 1
      end

      println("($(myid())) New position:")
      println(x)
      println("")
      println("")

    #End while loop
    end

    println("($(myid())) about to shrink")

    #Attempt to shrink variable bounds based on new point
    shrink(x)

  end

  #=
  Attempts to shrink the bounds on a variable range given a point
  =#
  function shrink(x)
    global new_bounds

    println("($(myid())) Trying to shrink...")

    #Attempt to get a lock on new variable bounds
    put!(mutex, true)

    println("($(myid())) Got lock on shrink")

    #Counter for dimensions
    counter = 1

    #For each dimension of the point
    for x_var in x

      #If lower bound is set
      if isdefined(new_bounds, counter, 1)

        #If point has value greater than current minimum value
        if x_var < new_bounds[counter, 1]

          old_value = new_bounds[counter, 1]

          println("($(myid())) Lower bound set for dimension $counter, old value is $old_value, new value is $x_var")

          #Set the new lower bound to this points value
          new_bounds[counter, 1] = x_var

        end

      #Automatically the smallest point so far for this dimension
      else

        println("($(myid())) No upper bound set for dimension $counter, new value is $x_var")

        #Set the upper bound to this points value
        new_bounds[counter, 1] = x_var

      end

      #If upper bound is set
      if isdefined(new_bounds, counter, 2)

        #If point has value greater than current maximum value
        if x_var > new_bounds[counter, 2]

          old_value = new_bounds[counter, 2]

          println("($(myid())) Upper bound set for dimension $counter, old value is $old_value, new value is $x_var")

          #Set the new lower bound to this points value
          new_bounds[counter, 2] = x_var

        end

      #Automatically the smallest point so far for this dimension
      else

        println("($(myid())) Upper bound set for dimension $counter, new value is $x_var")

        #Set the lower bound to this points value
        new_bounds[counter, 2] = x_var

      end

      #Increment dimension counter
      counter = counter + 1

    end

    #Release lock
    take!(mutex)

  end

  #=
  Sets the alpha value for the algorithm
  =#
  function set_alpha(value)
    global alpha

    alpha = value

  end

  #=
  Sets the beta value for the algorithm
  =#
  function set_beta(value)
    global beta

    beta = value

  end

  #=
  Sets the number of points to generate for the algorithm
  =#
  function set_points_to_generate(value)
    global points_to_generate

    points_to_generate = value

  end

  #=
  Sets the number of points to generate for the algorithm
  =#
  function set_max_iterations(value)
    global max_iterations

    max_iterations = value

  end

  #=
  Sets the value for an unbounded upper variable
  =#
  function set_unbounded_upper_value(value)
    global unbounded_upper_value

    unbounded_upper_value = value

  end

  #=
  Sets the value for an unbounded lower variable
  =#
  function set_unbounded_lower_value(value)
    global unbounded_lower_value

    unbounded_lower_value = value

  end

end
