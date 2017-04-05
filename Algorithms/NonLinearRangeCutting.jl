module NonLinearRangeCutting

  using NLPModels
  using AmplNLReader

  unbounded_lower_value = -(1*10)^3   #Value to replace infinity with on bounds
  unbounded_upper_value = (1*10)^3    #Value to replace infinity with on bounds
  new_bounds = Array{Float64}
  maximum_sampling_points = 10000      #Maximum sampling points for a given cut range
  minimum_sampling_points = 100        #Minimum sampling points for a given cut range
  point_every_x = 100                 #Sample a point every x units

  function test()
    m = AmplModel("/root/Documents/bounds_shrinker/basic_model.nl")
    new_bounds_ref = Array{Float64}

    run(m, new_bounds_ref)
  end

  #=
  Attempts to shrink the bounds on the given NLP by randomly generating
  points within a given range. If no feasible points are found then a
  cut is applied to the variable bound.
  =#
  function run(m::AmplModel, new_bounds_ref)
    global new_bounds

    #Array for shrunked bounds
    new_bounds = Array{Float64}(m.meta.nvar, 2)

    #Loop each variable
    d_count = 1
    while d_count <= m.meta.nvar

        #Cut the upper bound
        cut_upper(m, d_count)

        #Cut the lower bound
        cut_lower(m, d_count)

        #increment variable counter
        d_count = d_count + 1

    end

    #Save current bounds in new bounds
    counter = 1
    while counter <= m.meta.nvar

      #Update new bounds reference with determined bounds
      new_bounds_ref[counter, 1] = new_bounds[counter, 1]
      new_bounds_ref[counter, 2] = new_bounds[counter, 2]

      counter = counter + 1
    end

  end

  #=
  Generates random points at a specified increment inside the range
  of a specified variable.
  =#
  function generate_points(m, d_cutting, min_value, max_value, total_points)

    #Array of random points to return
    random_points = Array{Array{Float64}}(total_points)

    #Points generated counter
    p_count = 1

    println("Generated $total_points for dimension $d_cutting")

    #For each random point to generate
    while p_count <= total_points

      #Initialize random point
      p = Float64[]

      #Counter for dimension loop
      d_count = 1

      #For each dimension
      while d_count <= m.meta.nvar

        #If dimension under consideration is the one we are cutting
        if d_count == d_cutting

          #Calculate random position
          rand_val = rand(min_value:max_value)
          println("X[$d_count] = $rand_val")

          #Push random position in cut range to point
          push!(p, rand_val)

        #Not dimension we are cutting, choose random value
        else

          #If negative infinity use infinity value
          if m.meta.lvar[d_count] == -Inf
            lower_bound_int = unbounded_lower_value
          else
            #Lower bound as integer
            lower_bound_int = Int(floor(m.meta.lvar[d_count]))
          end

          #If infinity use infinity value
          if m.meta.uvar[d_count] == Inf
            upper_bound_int = unbounded_upper_value
          else
            #Upper bound as integer
            upper_bound_int = Int(ceil(m.meta.uvar[d_count]))
          end

          #Calculate random position
          rand_val = rand(lower_bound_int:upper_bound_int)

          #Push random position in total variable range to point
          push!(p, rand_val)

        end

        #Increment dimension counter
        d_count = d_count + 1

      end

      #Add point to array to return
      random_points[p_count] = p

      #Increment point counter
      p_count = p_count + 1

    end

    return random_points

  end

  #=
  Attempts to perform a cut to the upper bound on a given variable
  =#
  function cut_upper(m, d_count)
    global point_every_x, maximum_sampling_points, minimum_sampling_points, new_bounds

    println("testing cutting UPPER range")

    #Percent of variable range to cut
    cut_percent = 0.30

    #save upper bound to variable
    upper_bound_int = m.meta.uvar[d_count]

    #If infinity use infinity value
    if upper_bound_int == Inf
      upper_bound_int = unbounded_upper_value
    end

    #Get range of values this variable takes in this cut range
    upper_bound_lower_range_int = upper_bound_int - abs(upper_bound_int * cut_percent)

    #Generate a point every x
    point_increment = point_every_x

    #Calculate number of points that will be generated based on this
    total_points = (upper_bound_int - upper_bound_lower_range_int) / point_increment

    #if too many points will be generated set point increment to max allowed
    if total_points > maximum_sampling_points
      total_points = maximum_sampling_points
    end

    #if not enough points will be generated set point increment to min allowed
    if total_points < minimum_sampling_points
      total_points = minimum_sampling_points
    end

    #Generate points in the cut region
    random_points = generate_points(m, d_count, upper_bound_lower_range_int, upper_bound_int, total_points)

    println("Finished generated random points")

    #Determine if cut can be performed
    can_cut = can_we_cut(m, total_points, random_points)

    #If we can cut
    if can_cut

      #Set the upper bound to this points value
      new_bounds[d_count, 2] = upper_bound_lower_range_int

      println("we should perform the upper cut")

    else

      #Set the upper bound to the default upper bound
      new_bounds[d_count, 2] = m.meta.uvar[d_count]

      println("we cannot perform the upper cut")
    end

  end

  #=
  Attempts to perform a cut to the lower bound on a given variable
  =#
  function cut_lower(m, d_count)
    global point_every_x, maximum_sampling_points, minimum_sampling_points, new_bounds

    println("testing cutting LOWER range")

    #Percent of variable range to cut
    cut_percent = 0.30

    #save lower bound to variable
    lower_bound_int = m.meta.lvar[d_count]

    #If infinity use infinity value
    if lower_bound_int == -Inf
      lower_bound_int = unbounded_lower_value
    end

    #Get range of values this variable takes in this cut range
    lower_bound_upper_range_int = lower_bound_int + abs(lower_bound_int * cut_percent)

    println("Lower bound range is $lower_bound_int to $lower_bound_upper_range_int")

    #Generate a point every x
    point_increment = point_every_x

    #Calculate number of points that will be generated based on this
    total_points = (lower_bound_upper_range_int - lower_bound_int) / point_increment

    #if too many points will be generated set point increment to max allowed
    if total_points > maximum_sampling_points
      total_points = maximum_sampling_points
    end

    #if not enough points will be generated set point increment to min allowed
    if total_points < minimum_sampling_points
      total_points = minimum_sampling_points
    end

    #Generate points in the cut region
    random_points = generate_points(m, d_count, lower_bound_int, lower_bound_upper_range_int, total_points)

    println("Finished generated random points")

    #Determine if cut can be performed
    can_cut = can_we_cut(m, total_points, random_points)

    #If we can cut
    if can_cut

      #Set the upper bound to this points value
      new_bounds[d_count, 1] = lower_bound_upper_range_int

      println("we should perform the upper cut")

    else

      #Set the upper bound to the default upper bound
      new_bounds[d_count, 1] = m.meta.lvar[d_count]

      println("we cannot perform the upper cut")
    end

  end

  #=
  Determines whether or not we can perform a cut given the random points
  =#
  function can_we_cut(m, total_points, random_points)

    #Used to determine if equality constraint satisfied
    equality_constraints = Array{Bool}(m.meta.ncon, 3)
    feasible_points = Array{Bool}(m.meta.ncon, total_points)
    is_equality_constraint = Array{Bool}(m.meta.ncon)

    #Reset all arrays to false
    p_counter = 1
    c_counter = 1
    while c_counter <= m.meta.ncon
      equality_constraints[c_counter, 1] = false
      equality_constraints[c_counter, 2] = false
      equality_constraints[c_counter, 3] = false
      is_equality_constraint[c_counter] = false

      while p_counter <= total_points

        feasible_points[c_counter] = false
        p_counter = p_counter + 1
        c_counter = c_counter + 1

      end
    end

    #Loop each sampling point
    point_counter = 1
    for x in random_points

      println("On a new point")

      #= Attempt to evaluate all constraints at point
      Taken from Sarrankans Get a Nucleus method =#
      value = try
        NLPModels.cons(m,x)
      catch AmplException
        continue
      end

      #For each constraint evaluation
      for z = 1 : length(value)

        #If it is  inequality constraint
        if findfirst(m.meta.jfix,z) <= 0

          println("inequality constraint")

          #Check if inequality constraint violating
          if (value[z] >= m.meta.lcon[z] && value[z] <= m.meta.ucon[z])

            println("constraint $z has feasible point")

            #No violation, it is a feasible point
            feasible_points[z] = true

            #Only 1 feasible point is required, move to next constraint
            continue

          else

            println("constraint $z has infeasible point")

          end

        #It is an equality constraint
        else

          #Set this constraint to equality constraint type
          is_equality_constraint[z] = true

          println("Is equality constraint")

          #Found a value greater than
          if(value[z] > m.meta.lcon[z])
            println("found value greater than")
            equality_constraints[z, 1] = true

          #Found a value lower than
        elseif(value[z] < m.meta.ucon[z])
            println("found value less than")
            equality_constraints[z, 2] = true

          #Found a value on the equality constraint
          else
            println("found value on equality constraint")
            equality_constraints[z, 3] = true
          end

        end
      end

      point_counter = point_counter + 1
    end


    #Can we cut or not
    can_cut = false

    #Loop each analyzed constraint
    c_counter = 1
    while c_counter <= m.meta.ncon

      #if the constraint is an equality constraint
      if (is_equality_constraint[c_counter])
        println("Constraint $c_counter is equality")

        #If al the sample points are greater than constraint value or less than the constraint value perform cut
        if ((equality_constraints[c_counter, 1] == true && equality_constraints[c_counter, 1] == false)
          || (equality_constraints[c_counter, 1] == false && equality_constraints[c_counter, 1] == true))

          println("at least one equality constraint was not satisfied ever, CAN CUT")
          can_cut = true
          break

        else

        end

      #if the constraint is an inequality constraint
      else
        println("Constraint $c_counter is inequality")

        #At least one constraint is not satisfied
        if feasible_points[c_counter] == false
            println("at least one constraint was not satisfied ever, CAN CUT")
            can_cut = true
            break
        end

      end

      c_counter = c_counter + 1
    end

    #Return whether or not cut can be made
    if can_cut
      return true
    else
      return false
    end

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

  #=
  Sets the maximum number of random points to generate
  =#
  function set_max_random_points(value)
    global maximum_sampling_points

    maximum_sampling_points = value
  end

  #=
  Sets the minimum number of random points to generate
  =#
  function set_min_random_points(value)
    global minimum_sampling_points

    minimum_sampling_points = value
  end

  #=
  Sets the ratio of sampling points to generate
  =#
  function set_point_every_x(value)
    global point_every_x

    point_every_x = value
  end

end
