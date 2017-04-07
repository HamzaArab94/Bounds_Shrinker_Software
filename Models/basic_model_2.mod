## Very basic non linear example
var x1;
var x2;

maximize final_result: x1 + x2;
subject to constraint_1: x2 <= -(x1-3)^2 + 11000;
subject to constraint_2: x2 >= (x1-3)^2 + 10000;
