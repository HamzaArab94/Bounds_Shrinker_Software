using AmplNLReader,Gtk.ShortNames

#Numerical Unbounded Constant
numUnboundedU = (1*10)^20
numUnboundedL = -(1*10)^20

function isBounded(model)
  scaleLower = Any[]
  scaleUpper = Any[]
  scaleBoth = Any[]
  nvar = model.meta.nvar
  lvar = model.meta.lvar
  uvar = model.meta.uvar
  for i = 1:nvar
      if(lvar[i] <= numUnboundedL && uvar[i] >= numUnboundedU)
        push!(scaleBoth,i)
      elseif(lvar[i]>= numUnboundedL && uvar[i] >= numUnboundedU)
        push!(scaleUpper,i)
      elseif(lvar[i] <= numUnboundedL && uvar[i] <= numUnboundedU)
        push!(scaleLower,i)
      end
  end
  return (length(scaleLower) == 0 && length(scaleUpper) == 0 && length(scaleBoth) == 0)
end

#requires cute set, deletes too!
function sortBoundedUnBounded()
  FileList = readdir(pwd()*"/CuteSet")
  for file in FileList
    name = AbstractString(pwd()*"/CuteSet/"file)
    model = AmplModel(name)
    if(isBounded(model))
      mv(name,AbstractString(pwd()*"/Bounded/"file))
    else
      mv(name,AbstractString(pwd()*"/Unbounded/"file))
    end
  end
end

FileList = readdir(pwd()*"/Bounded/11To50VarsConstraints")
for file in FileList
  name = AbstractString(pwd()*"/Bounded/11To50VarsConstraints"file)
  model = AmplModel(name)
  if(length(model.meta.jfix) > 0)
    print(name)
  end
end
