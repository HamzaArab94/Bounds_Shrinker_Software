#Experimental Tester Script for Algorithm

include("NonLinearIntervalSampling.jl")

BoundedModelPaths = ["/Models/Bounded/Level 1/TwoVariables/",
"/Models/Bounded/Level 1/LessThan10VarsConstraints/",
"/Models/Bounded/Level 2/11To50VarsConstraints/",
"/Models/Bounded/Level 2/100To500VarsConstraints/"]

UnboundedModelPaths = ["/Models/Unbounded/Level 1/TwoVariables/",
"/Models/Unbounded/Level 1/LessThan10VarsConstraints/",
"/Models/Unbounded/Level 2/11To50VarsConstraints/",
"/Models/Unbounded/Level 2/100To500VarsConstraints/"]

function AlgorithmTester(Algorithm::Function)
  for path in BoundedModelPaths
    println(path)
    #Used to run a batch of test models
    FileList = readdir(pwd()*path)
     for file in FileList
      print(file * "\n")
       #CHANGE ALGORITHM PARAMETERS HERE
       Bounds = Algorithm(AmplModel(pwd()*path*file),((1*10)^20),(-(1*10)^20))
     end
  end
  for path in UnboundedModelPaths
    #Used to run a batch of test models
    FileList = readdir(pwd()*path)
     for file in FileList
      print(file * "\n")
       #CHANGE ALGORITHM PARAMETERS HERE
       Bounds = Algorithm(AmplModel(pwd()*path*file),((1*10)^20),(-(1*10)^20))
     end
  end
end

AlgorithmTester(NonLinearIntervalSampling)
