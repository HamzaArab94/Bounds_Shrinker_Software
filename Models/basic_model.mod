#AMPL MODEL

#Variables
var x1;
var x2;

#Objective Function 
maximize final_result: x1 + x2;

#Constraints
subject to constraint_1: x1^2 + x2 <= 10;

#Bounds
subject to constraint_2: x2 <= 5;
